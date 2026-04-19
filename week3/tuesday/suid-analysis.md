# SUID Analysis: deploy.sh

## Question 1: Why does the kernel ignore SUID on interpreted scripts?

When the kernel executes a file beginning with `#!` (a shebang), it does not
execute the file directly — it launches the interpreter (e.g. /bin/bash) and
passes the script as an argument. The SUID bit applies to the file being
executed, not to files passed as arguments. Since bash is the process actually
running, and bash is not SUID, the elevated privileges never take effect. The
kernel made this decision deliberately to prevent privilege escalation through
interpreter manipulation.

## Question 2: Why is SUID plus world-write still a critical finding?

Even though the kernel ignores SUID on the script itself, the combination
creates a different attack path. The script is executed by a root-owned cron
job. World-write permissions mean any user on the system can replace the
contents of deploy.sh with arbitrary commands. When the cron job runs next,
it executes the attacker's commands as root — not because of SUID, but because
the cron job itself runs as root. The SUID bit is irrelevant; the world-write
permission is the actual vulnerability.

## Question 3: What would make this exploitable in practice?

The exploit requires two conditions: write access to the script (provided by
world-write permissions) and a mechanism to execute it with elevated privileges
(provided by the root-owned cron job). An attacker with any local user account
could write a reverse shell or privilege escalation payload into deploy.sh,
then wait for the cron job to fire. The fix is to remove world-write (chmod 750)
and ensure the script is owned by root with no write access for other users.
