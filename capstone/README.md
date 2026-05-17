# KijaniKiosk Capstone

## Track A: Infrastructure-First

This project implements:
- Terraform staging namespace provisioning
- Ansible staging configuration
- Kubernetes multi-environment deployment
- Jenkins CI/CD pipeline with approval gate
- Prometheus alerting
- Serverless receipt chain integration

## Environments
- staging
- production

## Core Flow
kk-payments → Kubernetes → receipt event → serverless handler → logging

