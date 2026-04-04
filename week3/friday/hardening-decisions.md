# Hardening Decisions – Kijani Payments

## Systemd Hardening
- `NoNewPrivileges=true` – Prevents privilege escalation
- `PrivateTmp=true` – Isolates temporary files
- `PrivateDevices=true` – Denies hardware access
- `PrivateUsers=true` – Private UID/GID namespace
- `PrivateNetwork=true` – Deny network access
- `ProtectSystem=strict` – Read-only access to OS files
- `ProtectHome=true` – Protect home directories
- `RestrictSUIDSGID=true` – Deny SUID/SGID escalation
- `MemoryDenyWriteExecute=true` – Block writable+executable memory

## Network Restrictions
- `RestrictAddressFamilies=AF_UNIX` – Only local sockets
- `IPAddressDeny=any` – Deny all IP communication

## System Calls
- `SystemCallFilter=@system-service` – Allow only essential calls
- Deny privileged, resources, mount, raw-io, reboot, swap, clock, debug, module calls

## Capabilities
- `CapabilityBoundingSet=` – Remove all capabilities

## Notes
- Designed for **least privilege** execution
- Maximizes security score in `systemd-analyze security`
