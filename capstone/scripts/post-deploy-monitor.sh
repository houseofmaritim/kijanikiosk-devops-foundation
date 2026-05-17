#!/bin/bash

THRESHOLD=3
FAIL_COUNT=0

START_TIME=$(date +%s)

echo "MONITOR START: $(date '+%H:%M:%S')" > rollback-evidence.txt

while true
do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/health)

  if [ "$STATUS" != "200" ]; then
    FAIL_COUNT=$((FAIL_COUNT+1))
    echo "FAIL detected at $(date '+%H:%M:%S') (count=$FAIL_COUNT)" >> rollback-evidence.txt

    if [ $FAIL_COUNT -eq 1 ]; then
      echo "T0 (fault observed): $(date '+%H:%M:%S')" >> rollback-evidence.txt
    fi
  else
    FAIL_COUNT=0
  fi

  if [ "$FAIL_COUNT" -ge "$THRESHOLD" ]; then
    T1=$(date +%s)
    echo "T1 (rollback triggered): $(date '+%H:%M:%S')" >> rollback-evidence.txt

    bash rollback.sh

    T2=$(date +%s)
    echo "T2 (rollback complete): $(date '+%H:%M:%S')" >> rollback-evidence.txt

    DURATION=$((T2 - START_TIME))
    echo "TOTAL DURATION: ${DURATION}s" >> rollback-evidence.txt

    break
  fi

  sleep 5
done
