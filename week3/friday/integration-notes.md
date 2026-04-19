# Integration Challenge Notes

## Challenge A: ProtectSystem=strict and EnvironmentFile

**Conflict:** ProtectSystem=strict makes /etc and /usr read-only for the
service process. If EnvironmentFile paths were under /etc/kijanikiosk/,
the service would fail to read its own configuration at startup.

**Options considered:**
1. Move config files to /opt/kijanikiosk/config/ (not affected by ProtectSystem)
2. Add ReadOnlyPaths= to explicitly allow the /etc path
3. Use BindReadOnlyPaths= to mount the config into an accessible location

**Decision:** Option 1 — all config files live under /opt/kijanikiosk/config/
which is explicitly listed in ReadWritePaths= (for shared/logs) and is not
affected by ProtectSystem=strict. This is the cleanest solution because it
keeps configuration co-located with the application and avoids exceptions
to the hardening policy.

## Challenge B: Monitoring User and Health Directory ACLs

**Conflict:** The health check JSON file is written by the provisioning
script running as root. The monitoring system and operators need to read
it without sudo. The /health directory was not in the original access model.

**Options considered:**
1. Make the file world-readable (chmod 644) — too permissive
2. Add health directory to the kijanikiosk group model — consistent with
   existing access model
3. Create a separate monitoring user with ACL access

**Decision:** Option 2 — /opt/kijanikiosk/health/ is owned by
root:kijanikiosk with mode 750. The JSON file is owned by
kk-logs:kijanikiosk with mode 640. Any member of the kijanikiosk group
(sharon, kk-api, kk-payments, kk-logs) can read it. No ACLs needed
because group membership already provides the right access.

## Challenge C: logrotate postrotate and PrivateTmp

**Conflict:** kk-logs has PrivateTmp=true which gives it an isolated /tmp.
The logrotate postrotate script needs to signal kk-logs to re-open its
log file handles after rotation. The standard `systemctl reload` only
works if the unit has an ExecReload= directive.

**Options considered:**
1. systemctl reload kk-logs.service — fails if no ExecReload= defined
2. systemctl restart kk-logs.service — works but causes brief service
   interruption
3. systemctl kill --signal=USR1 kk-logs.service — sends USR1 signal
   which is the Unix convention for log rotation (used by nginx, etc.)

**Decision:** Option 3 — `systemctl kill --signal=USR1` sends the signal
directly to the service process without requiring ExecReload= and without
restarting the service. PrivateTmp=true does not affect signal delivery
since signals are sent via the kernel, not through the filesystem.
The `|| true` ensures logrotate does not fail if kk-logs is not running.

## Challenge D: Package Holds on Dirty VM

**Conflict:** nginx and nodejs were already installed and held from
Wednesday's provisioning run. Running apt-get install again on a held
package produces a warning but succeeds. However if versions diverged
the hold may have been bypassed.

**Options considered:**
1. Check installed version matches expected version, fail loudly if not
2. Skip install if package already present at any version
3. Always attempt install and let apt handle it

**Decision:** Option 2 — the script checks if the package is installed
using dpkg -l and skips installation if found (matching ii or hi status).
This avoids unnecessary apt operations on a dirty VM and handles the hold
correctly. The held status means the version cannot drift without explicit
intervention, so version mismatch is unlikely in normal operation.
