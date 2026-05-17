#!/bin/bash

echo "ROLLBACK STARTED at $(date '+%H:%M:%S')" >> rollback-evidence.txt

# Stop green (bad environment)
docker stop kijanikiosk-green 2>/dev/null

# Ensure blue is running
docker start kijanikiosk-blue 2>/dev/null

# IMPORTANT: restore nginx routing
docker exec kijanikiosk-nginx sh -c "sed -i 's/kijanikiosk-green/kijanikiosk-blue/g' /etc/nginx/nginx.conf && nginx -s reload"

echo "Rollback completed at $(date '+%H:%M:%S')" >> rollback-evidence.txt
