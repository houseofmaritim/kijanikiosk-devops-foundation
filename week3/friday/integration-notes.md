# Integration Notes – KijaniKiosk

## Services
- **kk-api.service**
  - Required by: `kk-payments`
  - Dependency: `After=kk-api.service` ensures API is running first
- **kk-payments.service**
  - Isolated, hardened service, communicates via UNIX sockets
- **kk-logs**
  - Centralized log storage for auditing and troubleshooting

## Ports
- **22** – SSH access
- **80** – HTTP traffic
- **3001** – Payments API (restricted to local and monitoring subnet)

## Observations
- Systemd hardening ensures no unintended access between services
- Firewall rules enforce isolation and network segmentation
