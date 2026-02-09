## Purpose

This folder contains infrastructure for a hybrid deployment model:
- Application runs locally
- Monitoring runs on AWS

The goal is to gain cloud-grade observability without moving the entire application to the cloud.

## Why a hybrid setup?

This approach was chosen for these reasons:

1. Cost efficiency

- No always-on compute for the application
- AWS costs scale with actual telemetry usage
- Monitoring infrastructure can be stopped or minimized when not needed

2. No disruption to local development

- Existing local setup (infra-local) remains unchanged
- No need to expose local services to the public internet
- Telemetry is pushed outbound only

3. Realistic industry scenario

- Many teams run workloads on-prem or locally
- Centralized monitoring is often hosted in the cloud
- This reflects real-world hybrid environments

4. Clear migration path

- Local → Hybrid (this folder)
- Hybrid → Full AWS (EKS) later
- Monitoring architecture stays largely the same

## What lives here

- This folder provisions AWS-side monitoring only
  -- Amazon Managed Prometheus (metrics storage)
  -- Grafana on EC2 (visualization, IaaS-style)
  --S3 (cheap log retention)
- The application itself is out of scope for this folder.

## When to use this setup

- Developing locally but wanting persistent dashboards
- Learning hybrid cloud monitoring
- Demonstrating DevOps architecture with cost constraints
- Preparing for a future EKS deployment

## Notes

- Infrastructure is managed with Terraform and executed locally
- This setup prioritizes simplicity over perfection
- Refactoring into shared modules may happen later if needed