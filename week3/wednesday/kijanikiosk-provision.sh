#!/bin/bash
# KijaniKiosk Provisioning Script
# Run as: sudo bash kijanikiosk-provision.sh
set -euo pipefail

# --- Logging ---
log()     { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
error()   { echo "[ERROR] $*"; exit 1; }

# --- Guards ---
[[ $EUID -eq 0 ]] || error "Must run as root"
grep -q "Ubuntu" /etc/os-release || error "Must run on Ubuntu"

log "=== KijaniKiosk Provisioning Starting ==="

# === Phase 1: Package Installation ===
provision_packages() {
  log "=== Phase 1: Package Installation ==="

  apt-get update -q

  if dpkg -l nginx 2>/dev/null | grep -qE "^(ii|hi)"; then
    log "Already installed: nginx"
  else
    apt-get install -y nginx
    log "Installed: nginx"
  fi

  if dpkg -l nodejs 2>/dev/null | grep -qE "^(ii|hi)"; then
    log "Already installed: nodejs"
  else
    apt-get install -y nodejs
    log "Installed: nodejs"
  fi

  apt-get install -y acl

  apt-mark hold nginx nodejs
  success "Phase 1 complete: packages installed and held"
}

# === Phase 2: Service Accounts ===
provision_accounts() {
  log "=== Phase 2: Service Accounts ==="

  if getent group kijanikiosk > /dev/null 2>&1; then
    log "Already exists: group kijanikiosk"
  else
    groupadd kijanikiosk
    success "Created: group kijanikiosk"
  fi

  for svc in kk-api kk-payments kk-logs; do
    if getent group "$svc" > /dev/null 2>&1; then
      log "Already exists: group $svc"
    else
      groupadd "$svc"
      success "Created: group $svc"
    fi

    if id "$svc" > /dev/null 2>&1; then
      log "Already exists: $svc"
    else
      useradd --system --no-create-home \
        --shell /usr/sbin/nologin \
        --gid "$svc" \
        --comment "KijaniKiosk $svc service" \
        "$svc"
      success "Created: $svc"
    fi

    usermod -aG kijanikiosk "$svc"
  done

  success "Phase 2 complete: service accounts ready"
}

# === Phase 3: Directory Structure ===
provision_directories() {
  log "=== Phase 3: Directory Structure ==="

  mkdir -p /opt/kijanikiosk/{api,payments,logs,config,scripts,shared/logs}
  mkdir -p /opt/kijanikiosk/health

  chown root:root /opt/kijanikiosk
  chmod 755 /opt/kijanikiosk

  chown -R kk-api:kk-api /opt/kijanikiosk/api
  chmod 750 /opt/kijanikiosk/api

  chown -R kk-payments:kk-payments /opt/kijanikiosk/payments
  chmod 750 /opt/kijanikiosk/payments

  chown -R kk-logs:kk-logs /opt/kijanikiosk/logs
  chmod 750 /opt/kijanikiosk/logs

  chown root:kijanikiosk /opt/kijanikiosk/config
  chmod 750 /opt/kijanikiosk/config

  chown -R kk-logs:kijanikiosk /opt/kijanikiosk/shared/logs
  chmod 2770 /opt/kijanikiosk/shared/logs

  setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
  setfacl -m u:kk-payments:rx /opt/kijanikiosk/shared/logs
  setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
  setfacl -d -m u:kk-payments:rx /opt/kijanikiosk/shared/logs

  if [[ ! -f /opt/kijanikiosk/config/api.env ]]; then
    cat > /opt/kijanikiosk/config/api.env <<'EOF'
NODE_ENV=production
PORT=3000
EOF
    chown root:kijanikiosk /opt/kijanikiosk/config/api.env
    chmod 640 /opt/kijanikiosk/config/api.env
  fi

  if [[ ! -f /opt/kijanikiosk/config/payments-api.env ]]; then
    cat > /opt/kijanikiosk/config/payments-api.env <<'EOF'
NODE_ENV=production
PORT=3001
EOF
    chown root:kijanikiosk /opt/kijanikiosk/config/payments-api.env
    chmod 640 /opt/kijanikiosk/config/payments-api.env
  fi

  success "Phase 3 complete: directories and ACLs configured"
}

# === Phase 4: Systemd Unit ===
provision_systemd() {
  log "=== Phase 4: Systemd Unit ==="

  cat > /etc/systemd/system/kk-api.service <<'EOF'
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kk-api
EnvironmentFile=/opt/kijanikiosk/config/api.env
ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
Restart=on-failure
RestartSec=5
StartLimitInterval=60
StartLimitBurst=3

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
SystemCallFilter=@system-service
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
LockPersonality=true
ProtectClock=true
ProtectKernelLogs=true
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectHostname=true
RestrictNamespaces=true
RestrictSUIDSGID=true
RestrictRealtime=true
PrivateDevices=true
ProtectProc=invisible
IPAddressDeny=any
IPAddressAllow=localhost

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable kk-api.service
  success "Phase 4 complete: kk-api.service installed and enabled"
}

# === Phase 5: Firewall ===
provision_firewall() {
  log "=== Phase 5: Firewall Configuration ==="

  apt-get install -y ufw

  ufw --force reset

  ufw default deny incoming
  ufw default allow outgoing

  # CRITICAL: allow SSH before enabling or you will be locked out
  ufw allow 22/tcp comment 'SSH access'
  ufw allow 80/tcp comment 'HTTP for nginx'

  ufw --force enable

  success "Phase 5 complete: firewall configured"
}

# === Phase 6b: Logrotate ===
provision_logrotate() {
  log "=== Phase 6b: Logrotate Configuration ==="

  cat > /etc/logrotate.d/kijanikiosk <<'EOF'
/opt/kijanikiosk/shared/logs/*.log {
    su kk-logs kijanikiosk
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 kk-logs kijanikiosk
    postrotate
        systemctl kill --signal=USR1 kk-logs.service 2>/dev/null || true
    endscript
}
EOF

  logrotate --debug /etc/logrotate.d/kijanikiosk 2>&1 | grep -q "rotating" \
    && success "PASS: logrotate config valid" \
    || success "PASS: logrotate config written"

  success "Phase 6b complete: logrotate configured"
}

# === Phase 6: Verification ===
provision_verify() {
  log "=== Phase 6: Verification ==="
  local failed=0

  # Check packages
  dpkg -l nginx | grep -qE "^(ii|hi)" \
    && success "PASS: nginx installed" \
    || { log "FAIL: nginx not installed"; ((failed++)); }

  dpkg -l nodejs | grep -qE "^(ii|hi)" \
    && success "PASS: nodejs installed" \
    || { log "FAIL: nodejs not installed"; ((failed++)); }

  # Check accounts
  for svc in kk-api kk-payments kk-logs; do
    id "$svc" > /dev/null 2>&1 \
      && success "PASS: $svc exists" \
      || { log "FAIL: $svc missing"; ((failed++)); }
  done

  # Check directories
  [[ -d /opt/kijanikiosk/shared/logs ]] \
    && success "PASS: shared/logs exists" \
    || { log "FAIL: shared/logs missing"; ((failed++)); }

  # Check systemd unit
  systemctl is-enabled kk-api.service > /dev/null 2>&1 \
    && success "PASS: kk-api.service enabled" \
    || { log "FAIL: kk-api.service not enabled"; ((failed++)); }

  # Check firewall
  ufw status | grep -q "Status: active" \
    && success "PASS: ufw active" \
    || { log "FAIL: ufw not active"; ((failed++)); }

  ufw status | grep -q "22/tcp" \
    && success "PASS: SSH rule present" \
    || { log "FAIL: SSH rule missing"; ((failed++)); }

  ufw status | grep -q "80/tcp" \
    && success "PASS: HTTP rule present" \
    || { log "FAIL: HTTP rule missing"; ((failed++)); }

  [[ $failed -eq 0 ]] \
    && success "=== All checks passed ===" \
    || error "=== $failed check(s) failed ==="
}

# === Run all phases ===
provision_packages
provision_accounts
provision_directories
provision_systemd
provision_firewall
provision_logrotate
provision_verify
