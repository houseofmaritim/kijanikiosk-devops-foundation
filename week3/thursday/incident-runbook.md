# KijaniKiosk Incident Runbook
**Date:** 2026-04-01
**Investigated by:** Sharon Kanyi
**Server:** kijanikioskk (172.20.10.3)
**Incident start:** 2026-03-31 20:30 UTC (fault injection time)

## Incident Summary
Three simultaneous faults caused 502 errors on the payments endpoint:
1. 1.5GB of unrotated log files consuming disk I/O
2. A rogue Node.js process occupying port 3001
3. A misconfigured UFW deny rule blocking port 3001 health checks

## Phase 1: Performance Findings
- CPU: 95.5% idle, 0% I/O wait at investigation time
- Memory: 285MB used of 1.9GB, no swap pressure
- Disk: 5.1GB used of 24GB (23%), /opt/kijanikiosk/shared/logs/ at 1.6G
- iostat showed minimal disk activity at investigation time

**Initial hypothesis (20:33 UTC):** Log accumulation caused disk pressure
during the write phase. By investigation time writes had completed but
1.6GB of unrotated logs remained on disk.

## Phase 2: Log Findings
- No kk-payments journal entries (service not deployed)
- No nginx upstream errors
- No logrotate config existed for kijanikiosk logs
- Three log files totalling 1.5GB found with no rotation policy

**Revised hypothesis (20:35 UTC):** Missing logrotate config allowed logs
to grow unbounded. Combined with port conflict and firewall rule, this
explains the 502 errors.

## Phase 3: Network Findings
- Port 3001 had no listener (rogue process had already been identified
  by PID from setup but was confirmed via ss -tlnp)
- UFW rule 3: DENY 3001/tcp with comment "MISCONFIGURED: blocks health checks"
- curl to localhost:3001 timed out confirming no listener

## Root Causes
1. **Log accumulation:** No logrotate config existed for
   /opt/kijanikiosk/shared/logs/. Three log files grew to 512MB each,
   totalling 1.5GB. During active writes this saturated disk I/O.
2. **Port conflict:** A rogue Node.js process (PID 2156) was listening
   on 127.0.0.1:3001, intercepting requests intended for kk-payments
   and returning HTTP 500 errors.
3. **Firewall misconfiguration:** UFW rule denied all traffic to port
   3001/tcp, blocking health checks from the monitoring system and
   preventing the load balancer from detecting the port conflict.

## Remediation Steps

### Fix order rationale
Port conflict first: fastest fix, immediately stops 500 errors.
Firewall second: restores health check visibility. If firewall had been
fixed before killing the rogue process, the monitoring system would have
seen port 3001 responding (with 500 errors from the rogue server) and
reported the service as healthy — a false positive that would cause the
load balancer to resume sending traffic while errors continued.
Log rotation third: addresses underlying disk issue.

### Fix 1: Kill rogue process
```
ps aux | grep rogue        # confirmed PID 2156
ps -p 2156 -o stat         # state was S (interruptible sleep)
kill -TERM 2156            # SIGTERM chosen because state was S not D
ss -tlnp | grep 3001       # confirmed port clear
```
SIGTERM was chosen over SIGKILL because the process state was S
(interruptible sleep), meaning it could handle the signal gracefully.
SIGKILL is only necessary for D state (uninterruptible sleep).

### Fix 2: Remove firewall rule
```
sudo ufw delete 3          # removed deny 3001/tcp rule
sudo ufw status numbered   # confirmed rule removed
```

### Fix 3: Log rotation
```
sudo nano /etc/logrotate.d/kijanikiosk   # created config with daily rotation
sudo logrotate --force /etc/logrotate.d/kijanikiosk
sudo rm /opt/kijanikiosk/shared/logs/*.log.1
df -h /                    # confirmed disk recovered from 5.1G to 3.6G
```

## Verification Results
- Port 3001: no listener (PASS)
- UFW: no deny rule for 3001 (PASS)
- Disk: recovered from 23% to 16% used (PASS)
- Log directory: 8KB (PASS)

## Prevention
1. Add logrotate config to provisioning script so newly provisioned
   servers always have log rotation configured
2. Add comment to firewall phase in provisioning script explicitly
   stating port 3001 deny rule must never be added
3. Add port 3001 to health check monitoring so rogue process would
   be detected within one health check interval
