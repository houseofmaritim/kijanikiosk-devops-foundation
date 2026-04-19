#!/bin/bash
echo "=== Service Accounts ==="
id kk-api
id kk-payments
id kk-logs
getent group kijanikiosk

echo "=== Directory Structure ==="
ls -la /opt/kijanikiosk/

echo "=== Config Files ==="
ls -la /opt/kijanikiosk/config/

echo "=== Shared Logs ==="
ls -la /opt/kijanikiosk/shared/

echo "=== ACLs: shared/logs ==="
getfacl /opt/kijanikiosk/shared/logs/

echo "=== ACLs: config ==="
getfacl /opt/kijanikiosk/config/

echo "=== SUID Files in /opt ==="
find /opt/kijanikiosk -perm /4000 -type f 2>/dev/null
echo "(empty result = PASS)"

echo "=== Sudo Policy for amina ==="
sudo -l -U amina

echo "=== Cross-service isolation ==="
sudo -u kk-api ls /opt/kijanikiosk/payments/ 2>&1 || echo "PASS: kk-api cannot access payments/"
sudo -u kk-payments ls /opt/kijanikiosk/api/ 2>&1 || echo "PASS: kk-payments cannot access api/"
sudo -u kk-api cat /opt/kijanikiosk/config/db.env && echo "PASS: kk-api can read config"
