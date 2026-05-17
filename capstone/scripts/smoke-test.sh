#!/bin/bash

echo "Checking kk-payments health..."

kubectl get pods | grep kk-payments

if [ $? -eq 0 ]; then
  echo "SMOKE TEST PASSED"
else
  echo "SMOKE TEST FAILED"
  exit 1
fi
