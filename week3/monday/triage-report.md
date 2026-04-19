# KijaniKiosk API Server - Triage Report
**Date:** 2026-03-31
**Investigated by:** Sharon Kanyi
**Server:** kijanikioskk (192.168.1.231)
**Incident start (approximate):** 2024-01-15 04:07:55 (from log evidence)

## Summary
A Python process is consuming 523MB (26.1%) of system RAM, simulating a memory
leak that would degrade API response times under load. An unrotated 271MB log
file exists at /var/log/kijanikiosk/access.log.1, indicating log rotation
failure. Application logs show a clear database connection failure cascade
beginning at 04:07:55, which is the likely root cause of the reported latency
increase.

## Process and Resource State
Top 3 processes by memory:
1. python3 (PID 11157, root) — 26.1% RAM, 523MB RSS — memory consumer process
   allocating 500x 1MB chunks, simulating a leak
2. fwupd (PID 11168, root) — 2.1% RAM, 42MB RSS — firmware update daemon, normal
3. multipathd (PID 340, root) — 1.3% RAM, 26MB RSS — disk multipath daemon, normal

Total memory: 1.9GB. Used: 789MB. The Python process alone accounts for the
majority of used memory. No swap configured — if memory pressure increases
further, the OOM killer will terminate processes.

No zombie (Z) or uninterruptible sleep (D) processes found.

## Filesystem and Disk
- Root partition (/dev/sda2): 16% used (3.5GB of 24GB) — not critical
- /var/log/kijanikiosk/access.log.1: 271MB — orphaned rotated log, not cleaned up
- /var/log/kijanikiosk/app.log: 4KB — current application log, normal size

The 271MB orphaned log file indicates log rotation ran but post-rotation cleanup
(compression and deletion of old logs) did not complete. On a smaller disk this
would be a critical finding. On this server it is a maintenance issue.

## Log Analysis
Error frequency from /var/log/kijanikiosk/app.log:
- 2 x Query timeout errors
- 2 x ECONNREFUSED (database unreachable)
- 2 x Database connection pool warnings
- 1 x Connection pool exhausted
- 1 x Memory usage warning (87%)
- 1 x Retry limit reached

Timeline:
- 03:45:10 — First warning: connection pool at 85%
- 04:01:33 — Pool at 94%
- 04:07:55 — Pool exhausted, requests queuing
- 04:08:01 — Query timeouts begin (SELECT * FROM orders, SELECT * FROM products)
- 04:09:12 — Memory warning at 87%
- 06:22:18 — Database completely unreachable (ECONNREFUSED on port 5432)
- 06:22:28 — Retry limit reached, database connection permanently failed

Pattern: The database connection pool was exhausted first, causing query timeouts,
then the database became entirely unreachable. The memory warning at 04:09:12
correlates with the pool exhaustion — likely queries were queued in memory,
increasing heap usage.

## Network and Service State
Listening ports:
- 0.0.0.0:80 — nginx (HTTP) — responding correctly
- 0.0.0.0:22 — sshd — responding correctly
- 127.0.0.53:53 — systemd-resolved — normal

nginx HTTP response: 200 OK in 3ms — web server itself is healthy.
No unexpected ports. No application service (port 3000/8080) is listening,
confirming the Node.js app process is not running in this environment.

## Assessment
The most likely root cause of the P95 latency increase is the database connection
pool exhaustion that began at 04:07:55. Once the pool was exhausted, incoming API
requests queued in memory rather than being served, causing response times to
spike. The subsequent complete database failure at 06:22:18 would have caused
requests to fail entirely rather than just slow down. The memory-consuming Python
process (PID 11157) compounds this by reducing available memory for request
queuing and application heap.

## Recommended Next Steps
1. **Immediate:** Kill the memory-consuming process (PID 11157) to reclaim 523MB
   of RAM: `sudo kill 11157`
2. **Immediate:** Investigate why the database on port 5432 became unreachable
   at 06:22 — check database server logs and connection limits
3. **Short-term:** Fix log rotation to automatically compress and delete old logs,
   and clean up /var/log/kijanikiosk/access.log.1 manually now
