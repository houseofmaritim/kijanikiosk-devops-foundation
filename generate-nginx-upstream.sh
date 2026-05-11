#!/bin/bash

ACTIVE=$(cat /tmp/kijanikiosk_active_env 2>/dev/null || echo blue)

if [ "$ACTIVE" = "blue" ]; then
  TARGET="kijanikiosk_blue"
else
  TARGET="kijanikiosk_green"
fi

echo "proxy_pass http://$TARGET;" > upstream.conf
