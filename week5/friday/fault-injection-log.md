# Fault Injection Log

| Stage | Fault Introduced | Observed Behaviour | Why This Is Correct |
|------|----------------|-------------------|--------------------|
| Lint | Syntax error in code | Pipeline stopped immediately, no further stages ran | Failing early prevents wasting resources on broken code |
| Build | Broken build script | Verify stage did not execute | Build must succeed before validation |
| Test | Forced test failure | Security audit still ran, pipeline failed after | Parallel checks ensure all validation results are visible |
| Security | Vulnerable dependency | Pipeline failed after audit | Prevents unsafe code from being released |
| Publish | Wrong Nexus URL | All stages passed except Publish | Ensures only valid artifacts are released |
