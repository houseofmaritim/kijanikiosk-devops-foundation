# Secrets Documentation (KijaniKiosk)

Secret name:
- kk-payments-secrets

Required keys:
- DB_PASSWORD
- STRIPE_API_KEY
- JWT_SECRET

Note:
These values are NOT stored in git.
They must be obtained from the DevOps team before cluster deployment.

Creation command:
kubectl create secret generic kk-payments-secrets \
  --from-literal=DB_PASSWORD=... \
  --from-literal=STRIPE_API_KEY=... \
  --from-literal=JWT_SECRET=... \
  -n kijani-project
