# KijaniKiosk Production Server: Security Decisions

**Prepared for:** Nia Okonkwo, Chief Executive Officer
**Prepared by:** Sharon Kanyi, Infrastructure Engineer
**Date:** 2026-04-01

## Summary

This document explains the security decisions made when building the
KijaniKiosk production server foundation. Each decision is written in
plain language with a clear statement of the risk it addresses. The
goal is to give you enough information to speak confidently about our
security posture to the board.

## Security Decisions

| Control | What it does | Risk mitigated |
|---------|-------------|----------------|
| Dedicated service accounts | Each service runs as its own restricted user, not as the system administrator | If one service is compromised, the attacker cannot access other services or system files |
| Private directories per service | Each service can only read its own files, not those of other services | A vulnerability in the payments service cannot expose API code or logs from other services |
| Encrypted credential storage | Database passwords and payment keys are stored in files readable only by the services that need them | Credentials cannot be read by other users or processes on the same server |
| Firewall with explicit rules | Only web traffic and administrative access are permitted; all other connections are blocked | Reduces the number of ways an attacker can reach the server from the internet |
| Service isolation | Each service is prevented from accessing system hardware, kernel internals, and other processes | Limits the damage an attacker can cause even if they successfully exploit a service |
| Automatic log rotation | Logs are automatically archived and deleted after 14 days | Prevents logs from filling the disk, which would cause all services to stop writing data |
| Persistent system logs | System events are saved to disk and survive reboots | Gives engineers a complete record of what happened before and during any incident |
| Package version pinning | Software versions are locked and cannot be automatically updated | Prevents untested updates from breaking the payments service unexpectedly |
| Monitored health checks | After every provisioning run, the server records whether each service is reachable | Gives the team immediate confirmation that provisioning succeeded and services are running |

## What This Posture Does Not Protect Against

The controls above significantly reduce our attack surface, but they do
not protect against everything. Specifically: if an attacker obtains
valid credentials for one of our service accounts through phishing or
a third-party breach, the service isolation controls will not stop them
from accessing that service's data. Additionally, these controls protect
the server infrastructure but do not replace application-level security
such as input validation, authentication, and encryption of data in
transit. A complete security posture requires both the infrastructure
foundation described here and secure application code built on top of it.
