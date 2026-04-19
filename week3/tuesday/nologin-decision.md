# nologin vs false: Service Account Shell Decision

For the KijaniKiosk service accounts (kk-api, kk-payments, kk-logs), we chose
`/usr/sbin/nologin` over `/bin/false` as the shell.

Both prevent interactive login, but they differ in one important way: nologin
prints a message ("This account is currently not available") before refusing
access, while /bin/false exits immediately with no output. We chose nologin
because it provides clearer feedback during debugging — if an engineer
accidentally attempts to switch to a service account during an incident, the
explicit message confirms the account exists but is intentionally restricted,
rather than a silent failure that could be mistaken for a misconfiguration.
In a production environment where multiple engineers may be working under
pressure, that clarity has operational value. The security outcome is identical
between the two choices.
