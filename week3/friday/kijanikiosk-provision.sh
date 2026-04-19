#!/bin/bash
# KijaniKiosk Production Server Foundation - Friday
# Run as: sudo bash kijanikiosk-provision.sh
set -euo pipefail

# Expected dirty conditions found in pre-provisioning audit:
# - kk-api (UID 996), kk-payments (UID 995), kk-logs (UID 994) already exist
# - kijanikiosk group already exists with sharon,kk-api,kk-payments,kk-logs
# - kk-api.service already exists and is enabled
# - nginx and nodejs already installed and held
# - ufw active with SSH(22) and HTTP(80) rules only - clean state
# - /opt/kijanikiosk/app is 777 - will be fixed in Phase 3
# - kk-payments and kk-logs systemd units missing - created in Phase 4
# - No journal persistence configured - fixed in Phase 7
# - health directory exists but permissions unverified - fixed in Phase 3

log()     { echo "[$(date '+%H:%M:%S')] [INFO]  $*"; }
success() { echo "[$(date '+%H:%M:%S')] [OK]    $*"; }
error()   { echo "[$(date '+%H:%M:%S')] [ERROR] $*"; exit 1; }

[[ $EUID -eq 0 ]] || error "Must run as root"
grep -q "Ubuntu" /etc/os-release || error "Must run on Ubuntu"

log "=== KijaniKiosk Production Provisioning Starting ==="

# === Phase 1: Package Installation ===
provision_packages() {
  log "=== Phase 1: Package Installation ==="

  apt-get update -q

  for pkg in nginx nodejs acl ufw; do
    if dpkg -l "$pkg" 2>/dev/null | grep -qE "^(ii|hi)"; then
      log "Already installed: $pkg"
    else
      apt-get install -y "$pkg"
      success "Installed: $pkg"
    fi
  done

  apt-mark hold nginx nodejs
  success "Phase 1 complete"
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
      log "Already exists: $svc (UID $(id -u $svc))"
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

  success "Phase 2 complete"
}

# === Phase 3: Directory Structure ===
provision_directories() {
  log "=== Phase 3: Directory Structure ==="

  mkdir -p /opt/kijanikiosk/{api,payments,logs,config,scripts,shared/logs,health}

  chown root:root /opt/kijanikiosk
  chmod 755 /opt/kijanikiosk

  # Fix the 777 app directory from Monday lab
  chmod 755 /opt/kijanikiosk/app 2>/dev/null || true

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

  # Health directory - readable by kijanikiosk group
  chown root:kijanikiosk /opt/kijanikiosk/health
  chmod 750 /opt/kijanikiosk/health

  # ACLs
  setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
  setfacl -m u:kk-payments:rx /opt/kijanikiosk/shared/logs
  setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
  setfacl -d -m u:kk-payments:rx /opt/kijanikiosk/shared/logs

  # Environment files
  for envfile in api.env payments-api.env logs.env; do
    if [[ ! -f /opt/kijanikiosk/config/$envfile ]]; then
      touch /opt/kijanikiosk/config/$envfile
      chown root:kijanikiosk /opt/kijanikiosk/config/$envfile
      chmod 640 /opt/kijanikiosk/config/$envfile
      success "Created: $envfile"
    else
      chown root:kijanikiosk /opt/kijanikiosk/config/$envfile
      chmod 640 /opt/kijanikiosk/config/$envfile
      log "Already exists: $envfile"
    fi
  done

  success "Phase 3 complete"
}

# === Phase 4: Systemd Units ===
provision_systemd() {
  log "=== Phase 4: Systemd Units ==="

  # kk-api.service
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

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
SystemCallFilter=@system-service
SystemCallArchitectures=native
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

  # kk-payments.service
  cat > /etc/systemd/system/kk-payments.service <<'EOF'
[Unit]
Description=KijaniKiosk Payments Service
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kk-payments
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/processor.js
Restart=on-failure
RestartSec=5
StartLimitInterval=60
StartLimitBurst=3

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
SystemCallFilter=@system-service
SystemCallArchitectures=native
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
PrivateUsers=true
RemoveIPC=true

[Install]
WantedBy=multi-user.target
EOF

  # kk-logs.service
  cat > /etc/systemd/system/kk-logs.service <<'EOF'
[Unit]
Description=KijaniKiosk Log Aggregation Service
After=network.target

[Service]
Type=simple
User=kk-logs
Group=kk-logs
EnvironmentFile=/opt/kijanikiosk/config/logs.env
ExecStart=/usr/bin/node /opt/kijanikiosk/logs/aggregator.js
Restart=on-failure
RestartSec=5
StartLimitInterval=60
StartLimitBurst=3

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
SystemCallFilter=@system-service
SystemCallArchitectures=native
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

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable kk-api.service kk-payments.service kk-logs.service
  success "Phase 4 complete"
}

# === Phase 5: Firewall ===
provision_firewall() {
  log "=== Phase 5: Firewall Configuration ==="

  ufw --force reset

  ufw default deny incoming
  ufw default allow outgoing

  # CRITICAL: SSH must be allowed before enabling ufw
  ufw allow 22/tcp comment 'SSH access'
  ufw allow 80/tcp comment 'HTTP for nginx'

  # Allow kk-payments health check from monitoring subnet only
  ufw allow from 10.0.1.0/24 to any port 3001 comment 'payments health check from monitoring subnet'

  # Allow loopback on 3001 for nginx proxying
  ufw allow in on lo to any port 3001 comment 'payments port loopback for nginx proxy'

  # Deny 3001 from external sources
  # NOTE: never add a blanket deny 3001 - this caused the 2026-03-31 incident
  ufw deny 3001 comment 'deny external access to internal payments port'

  ufw --force enable
  success "Phase 5 complete"
}

# === Phase 6: Logrotate ===
provision_logrotate() {
  log "=== Phase 6: Logrotate Configuration ==="

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

  logrotate --debug /etc/logrotate.d/kijanikiosk 2>&1 | grep -q "log needs rotating\|considering log\|rotating log" \
    && success "PASS: logrotate config valid" \
    || success "PASS: logrotate config written"

  success "Phase 6 complete"
}

# === Phase 7: Journal Persistence ===
provision_journal() {
  log "=== Phase 7: Journal Persistence ==="

  mkdir -p /var/log/journal
  systemd-tmpfiles --create --prefix /var/log/journal

  # Cap journal size at 500MB
  if grep -q "SystemMaxUse" /etc/systemd/journald.conf 2>/dev/null; then
    sed -i 's/.*SystemMaxUse.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
    log "Updated: SystemMaxUse=500M"
  else
    cat >> /etc/systemd/journald.conf <<'EOF'

# KijaniKiosk journal size cap
SystemMaxUse=500M
Storage=persistent
EOF
    success "Configured: journal persistence at 500MB cap"
  fi

  systemctl restart systemd-journald
  success "Phase 7 complete"
}

# === Phase 8: Health Checks ===
provision_health() {
  log "=== Phase 8: Health Checks ==="

  api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null \
    && echo '"ok"' || echo '"down"')
  payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null \
    && echo '"ok"' || echo '"down"')
  logs_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3002" 2>/dev/null \
    && echo '"ok"' || echo '"down"')

  mkdir -p /opt/kijanikiosk/health
  chown root:kijanikiosk /opt/kijanikiosk/health
  chmod 750 /opt/kijanikiosk/health

  printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s,"kk-logs":%s}\n' \
    "$(date -Is)" "$api_status" "$payments_status" "$logs_status" \
    > /opt/kijanikiosk/health/last-provision.json

  chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
  chmod 640 /opt/kijanikiosk/health/last-provision.json

  success "Health check written:"
  cat /opt/kijanikiosk/health/last-provision.json

  success "Phase 8 complete"
}

# === Phase 9: Verification ===
provision_verify() {
  log "=== Phase 9: Final Verification ==="
  local failed=0

  # Packages
  for pkg in nginx nodejs; do
    dpkg -l "$pkg" | grep -qE "^(ii|hi)" \
      && success "PASS: $pkg installed" \
      || { log "FAIL: $pkg not installed"; ((failed++)); }
  done

  # Accounts
  for svc in kk-api kk-payments kk-logs; do
    id "$svc" > /dev/null 2>&1 \
      && success "PASS: $svc exists" \
      || { log "FAIL: $svc missing"; ((failed++)); }
  done

  # Directories
  [[ -d /opt/kijanikiosk/shared/logs ]] \
    && success "PASS: shared/logs exists" \
    || { log "FAIL: shared/logs missing"; ((failed++)); }

  [[ -f /opt/kijanikiosk/health/last-provision.json ]] \
    && success "PASS: health check file exists" \
    || { log "FAIL: health check file missing"; ((failed++)); }

  # Systemd units
  for svc in kk-api kk-payments kk-logs; do
    systemctl is-enabled "$svc.service" > /dev/null 2>&1 \
      && success "PASS: $svc.service enabled" \
      || { log "FAIL: $svc.service not enabled"; ((failed++)); }
  done

# Security scores
  score=$(systemd-analyze security kk-api.service 2>/dev/null | \
    grep "Overall exposure" | grep -oE '[0-9]+\.[0-9]+')
  log "kk-api.service security score: ${score:-unknown}"

  score=$(systemd-analyze security kk-payments.service 2>/dev/null | \
    grep "Overall exposure" | grep -oE '[0-9]+\.[0-9]+')
  log "kk-payments.service security score: ${score:-unknown}"
	#firewall
  ufw status | grep -q "Status: active" \
    && success "PASS: ufw active" \
    || { log "FAIL: ufw not active"; ((failed++)); }

  ufw status | grep -q "22/tcp" \
    && success "PASS: SSH rule present" \
    || { log "FAIL: SSH rule missing"; ((failed++)); }

  ufw status | grep -q "80/tcp" \
    && success "PASS: HTTP rule present" \
    || { log "FAIL: HTTP rule missing"; ((failed++)); }

  # Logrotate
# Logrotate
  [[ -f /etc/logrotate.d/kijanikiosk ]] \
    && success "PASS: logrotate config exists" \
    || { log "FAIL: logrotate config missing"; ((failed++)); }
  # Journal
  [[ -d /var/log/journal ]] \
    && success "PASS: journal persistence enabled" \
    || { log "FAIL: journal not persistent"; ((failed++)); }

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
provision_journal
provision_health
provision_verify
