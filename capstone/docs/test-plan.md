# Test Plan

## Staging Tests
- Deploy kk-payments to staging namespace
- Verify ConfigMap ENV = staging
- Trigger sample payment event
- Confirm receipt handler logs event

## Production Tests
- Approval gate in Jenkins must be triggered
- Validate production ConfigMap ENV = production

## Failure Scenario
- Simulate 5xx error spike
- Verify Prometheus alert triggers
