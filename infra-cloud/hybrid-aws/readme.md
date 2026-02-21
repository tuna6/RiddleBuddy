# RiddleBuddy – Hybrid Local → Amazon Managed Prometheus Monitoring

This project deploys:

- Local Kubernetes application
- OpenTelemetry Collector
- Remote write to Amazon Managed Prometheus (AMP)
- Terraform-managed AWS + Kubernetes infrastructure

---

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

---

# Architecture

Local k3s cluster  
→ OpenTelemetry Collector  
→ SigV4 authentication  
→ Amazon Managed Prometheus (AMP)

Infrastructure managed via Terraform:
- AWS (AMP, IAM, S3 backend)
- Kubernetes (namespace, secret, Helm release)

---

