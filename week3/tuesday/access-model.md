# KijaniKiosk Access Model - Tuesday

## Directory Access Design

| Path | Owner | Group | Mode | Reasoning |
|------|-------|-------|------|-----------|
| /opt/kijanikiosk/ | root | root | 755 | Parent traversable by all, owned by root |
| /opt/kijanikiosk/api/ | kk-api | kk-api | 750 | Only API service can enter its own directory |
| /opt/kijanikiosk/payments/ | kk-payments | kk-payments | 750 | Only payments service can enter its directory |
| /opt/kijanikiosk/logs/ | kk-logs | kk-logs | 750 | Only logs service can enter its directory |
| /opt/kijanikiosk/config/ | root | kijanikiosk | 750 | Group-readable by all services via kijanikiosk group |
| /opt/kijanikiosk/config/*.env | root | kijanikiosk | 640 | Files readable by group, not world |
| /opt/kijanikiosk/shared/logs/ | kk-logs | kijanikiosk | 2770 | SGID ensures new files inherit kijanikiosk group |

## ACL Model

### /opt/kijanikiosk/shared/logs/
- kk-api: rwx (writes log entries)
- kk-payments: r-x (reads logs for audit correlation)
- sharon: r-x (operator read access)
- Default ACLs mirror the above so new files inherit correctly

### /opt/kijanikiosk/config/
- kk-api: r-x (reads db.env at startup)
- sharon: r-x (operator read access for debugging)

## Why ACLs over basic permissions
Basic Unix permissions support only one owner and one group. The shared/logs
directory needs kk-api to write, kk-payments to read, and sharon to read —
three different access levels for three different principals. ACLs allow this
without adding all services to a single permissive group that would break
isolation between service directories.

## Why SGID on shared/logs
Without SGID, new files created in shared/logs would inherit the creating
process's primary group (e.g. kk-api), making them unreadable by kk-payments.
SGID forces all new files to inherit the kijanikiosk group, ensuring the ACL
model remains intact after every write without manual intervention.
