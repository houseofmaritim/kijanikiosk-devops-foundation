# KijaniKiosk Access Model - Final (Friday)

## Directory Access Design

| Path | Owner | Group | Mode | Reasoning |
|------|-------|-------|------|-----------|
| /opt/kijanikiosk/ | root | root | 755 | Parent traversable by all |
| /opt/kijanikiosk/api/ | kk-api | kk-api | 750 | Only API service can enter |
| /opt/kijanikiosk/payments/ | kk-payments | kk-payments | 750 | Only payments service can enter |
| /opt/kijanikiosk/logs/ | kk-logs | kk-logs | 750 | Only logs service can enter |
| /opt/kijanikiosk/config/ | root | kijanikiosk | 750 | Group-readable by all services |
| /opt/kijanikiosk/config/*.env | root | kijanikiosk | 640 | Readable by group, not world |
| /opt/kijanikiosk/shared/logs/ | kk-logs | kijanikiosk | 2770 | SGID ensures new files inherit group |
| /opt/kijanikiosk/health/ | root | kijanikiosk | 750 | Written by root, readable by group |
| /opt/kijanikiosk/health/last-provision.json | kk-logs | kijanikiosk | 640 | Readable by kijanikiosk group |

## Health Directory (Added Friday)

The health directory was not in the original Tuesday access model.
It is written by the provisioning script running as root, then
ownership is transferred to kk-logs:kijanikiosk so the monitoring
system and operators can read it without sudo. The directory itself
is 750 so only root and the kijanikiosk group can access it.

## Logrotate Interaction

When logrotate rotates a log file in shared/logs/, it creates a new
empty file using the `create 0640 kk-logs kijanikiosk` directive.
The default ACLs on the directory propagate to new files automatically,
so kk-api retains write access and kk-payments retains read access
after every rotation without manual intervention.

The `su kk-logs kijanikiosk` directive in the logrotate config tells
logrotate to run as kk-logs:kijanikiosk when rotating, which is
required because the directory is group-writable by kijanikiosk,
not by root.

## ACL Model

### /opt/kijanikiosk/shared/logs/
- kk-api: rwx (writes log entries)
- kk-payments: r-x (reads logs for audit correlation)
- sharon: r-x (operator read access)
- Default ACLs mirror above so new files inherit correctly

### /opt/kijanikiosk/config/
- kk-api: r-x (reads db.env and api.env at startup)
- sharon: r-x (operator read access for debugging)
