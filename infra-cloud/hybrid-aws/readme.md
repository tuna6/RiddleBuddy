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

# Prerequisites
- Deepseek API Key
- AWS account
- AWS credentials exported:

```bash
export TF_VAR_aws_access_key=your_access_key
export TF_VAR_aws_secret_key=your_secret_key
export DEEPSEEK_API_KEY=your_api_key
```

- `kubectl` configured to your local cluster
- Terraform installed
- Helm installed

---

# Step 1 — Configure Terraform Backend (Required)

S3 bucket names are globally unique.

Create your own S3 bucket and update:

```
infra-cloud/hybrid-aws/terraform/backend/backend.tf
```

Example:

```hcl
backend "s3" {
  bucket = "<your-unique-bucket-name>"
  key    = "hybrid-aws/terraform.tfstate"
  region = "ap-southeast-1"
}
```

Then run:

```bash
cd infra-cloud/hybrid-aws/terraform/backend
terraform init -reconfigure
terraform apply
```

---

# Step 2 — Deploy AWS Infrastructure (AMP, IAM)

```bash
cd infra-cloud/hybrid-aws/terraform/aws
terraform init
terraform apply
```

This creates:
- AMP workspace
- IAM permissions
- Remote state outputs

---

# Step 3 — Deploy Monitoring Stack (Local Cluster)

```bash
cd infra-cloud/hybrid-aws/terraform/k8s
terraform init
terraform apply
```

If needed during first run:

```bash
terraform apply
```

(Second apply ensures secrets are fully wired before pod restart.)

This creates:
- `monitoring` namespace
- Kubernetes secret with AWS credentials
- OpenTelemetry Collector (Helm)

---

# Step 4 — Deploy Local Application

```bash
./deploy-local-app.sh
```

This deploys the sample application that exposes metrics.

---

# Verify Metrics

Check OpenTelemetry logs:

```bash
kubectl logs -n monitoring deploy/otel-opentelemetry-collector-agent
```

You should NOT see:

```
context deadline exceeded
```

Metrics should appear in Amazon Managed Prometheus.

---

# Notes

- Do NOT base64 encode values in Terraform Kubernetes secrets (provider handles encoding).
- Ensure AWS credentials are valid.
- Verify:
  - Secret values
  - AMP workspace ID
  - AWS region matches AMP region

---

# Cleanup

To destroy resources:

```bash
cd infra-cloud/hybrid-aws/terraform/k8s
terraform destroy

cd ../aws
terraform destroy
```
