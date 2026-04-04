#!/usr/bin/env bash
set -euo pipefail

log() { echo "[INFO] $1"; }
success() { echo "[OK] $1"; }
fail() { echo "[ERROR] $1"; exit 1; }

#################################
# Phase 1: Pre-checks
#################################
log "Phase 1: Pre-checks"

if [[ $EUID -ne 0 ]]; then
  fail "Run as root"
fi

#################################
# Phase 2: Users & Groups
#################################
log "Phase 2: Users & Groups"

for user in kk-api kk-payments kk-logs; do
  if id "$user" &>/dev/null; then
    log "$user already exists"
  else
    useradd -r -s /usr/sbin/nologin "$user"
    success "Created $user"
  fi
done

if getent group kijanikiosk > /dev/null; then
  log "Group kijanikiosk exists"
else
  groupadd kijanikiosk
  success "Created group kijanikiosk"
fi

#################################
# Phase 3: Packages & Dependencies
#################################
log "Phase 3: Packages and dependencies"

if apt-mark showhold | grep -q "^curl$"; then
  log "curl is on hold"
else
  log "curl is not on hold"
fi

apt-get update -y

for pkg in acl ufw; do
  if dpkg -s "$pkg" &>/dev/null; then
    log "$pkg already installed"
  else
    apt-get install -y "$pkg"
    success "Installed $pkg"
  fi
done

#################################
# Phase 4: Directories & ACLs
#################################
log "Phase 4: Directories and ACLs"

mkdir -p /opt/kijanikiosk/config
mkdir -p /opt/kijanikiosk/shared/logs
mkdir -p /opt/kijanikiosk/health

chmod 750 /opt/kijanikiosk/config
chown root:kijanikiosk /opt/kijanikiosk/config

chown -R root:kijanikiosk /opt/kijanikiosk

# NOW setfacl will work
setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:rx /opt/kijanikiosk/shared/logs

setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:rx /opt/kijanikiosk/shared/logs

success "ACLs applied"

#################################
# Phase 5: Firewall (UFW)
#################################
log "Phase 5: Firewall configuration"

# Reset firewall (IMPORTANT)
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp comment 'Allow SSH access'

# Allow HTTP
ufw allow 80/tcp comment 'Allow HTTP traffic'

# Allow monitoring subnet to payments
ufw allow from 10.0.1.0/24 to any port 3001 comment 'Monitoring subnet access'

# Allow loopback FIRST (important order)
ufw allow in on lo to any port 3001 comment 'Allow local access to payments'

# Deny external access to payments
ufw deny 3001 comment 'Block external access to payments'

# Enable firewall
ufw --force enable

success "Firewall configured"

#################################
# Phase 6: systemd Services
#################################
log "Phase 6: systemd services"

#################################
# kk-api.service
#################################
cat <<EOF > /etc/systemd/system/kk-api.service
[Unit]
Description=Kijani API Service

[Service]
User=kk-api
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/api.env

ExecStart=/usr/bin/sleep infinity

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

#################################
# kk-logs.service
#################################
cat <<EOF > /etc/systemd/system/kk-logs.service
[Unit]
Description=Kijani Logs Service

[Service]
User=kk-logs
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/logs.env

ExecStart=/usr/bin/sleep infinity

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

#################################
# kk-payments.service
#################################
cat <<EOF > /etc/systemd/system/kk-payments.service
[Unit]
Description=Kijani Payments Service
After=kk-api.service
Wants=kk-api.service

[Service]
User=kk-payments
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env

ExecStart=/usr/bin/sleep infinity

# Strong Hardening (target <2.5)
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
PrivateUsers=true
PrivateNetwork=true

ProtectSystem=strict
ProtectHome=true
ProtectClock=true
ProtectKernelLogs=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

RestrictSUIDSGID=true
RestrictRealtime=true
RestrictNamespaces=true

LockPersonality=true
MemoryDenyWriteExecute=true

# Network restrictions
RestrictAddressFamilies=AF_UNIX
IPAddressDeny=any

# System call filtering (BIG SCORE BOOST)
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources @mount @raw-io @reboot @swap @clock @debug @module

CapabilityBoundingSet=
EOF

# Reload systemd
systemctl daemon-reexec
systemctl daemon-reload

# Enable services
systemctl enable kk-api.service
systemctl enable kk-logs.service
systemctl enable kk-payments.service

success "systemd services created"
















































































