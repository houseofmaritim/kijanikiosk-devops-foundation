# Reflection

## What went wrong
Initial structure mixed environments and lacked clear separation between staging and production. This would have caused deployment ambiguity.

## Most important thing learned
CI/CD pipelines are only meaningful when connected to real environment boundaries and verification steps, not just echo stages.

## Second pass improvements
Add real cloud deployment for serverless, integrate actual Kubernetes rollout verification, and replace placeholders with live monitoring dashboards.
