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
