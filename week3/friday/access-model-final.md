# Access Model – Final

## Users
- **kk-api** – Runs the API service
- **kk-payments** – Runs the Payments service
- **kk-logs** – Handles log files

## Groups
- **kijanikiosk** – Main group for services

## Permissions
| Path                               | Owner       | Group       | Permissions | Notes                       |
|-----------------------------------|------------|------------|------------|----------------------------|
| /opt/kijanikiosk/shared/logs       | root       | kijanikiosk | 755        | Logs directory             |
| /opt/kijanikiosk/shared/logs/*.log | root       | kijanikiosk | 644        | Log files                  |
| /opt/kijanikiosk/config            | root       | kijanikiosk | 750        | Config files               |

## Key Points
- Services run with least privilege (non-root)
- Logs writable only by owner/group
- No external access to sensitive ports (3001)
