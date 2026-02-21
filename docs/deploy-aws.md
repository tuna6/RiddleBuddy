## Cloud Deployment

Full AWS deployment uses EKS, ALB, AMP, and Grafana on EC2.
See `infra-cloud/` for Terraform configs.

# Prerequisites
- Deepseek API Key
- AWS account
- AWS credentials exported:
- ECR hosted docker images in your prefered region

```bash
export TF_VAR_aws_access_key=your_access_key
export TF_VAR_aws_secret_key=your_secret_key
export DEEPSEEK_API_KEY=your_api_key
```

- `kubectl` configured to your local cluster
- Terraform installed
- Helm installed

---


# Step 1 — Preparation
You'll need to update these values for your own environment:

| Variable | Where | Description |
|---|---|---|
| `AWS_ACCOUNT_ID` | terraform.tfvars | Your AWS account |
| `AWS_REGION` | terraform.tfvars | Target region |
| `DEEPSEEK_API_KEY` | GitHub Secrets | AI API key |
| `AWS_ROLE_ARN` | GitHub Secrets | OIDC role for CI |
| `AMP_WORKSPACE_ID` | values.yaml | Managed Prometheus |
| `CLUSTER_NAME` | values.yaml | EKS cluster name |

# Step 2 — Configure Terraform Backend (Required)

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

# Step 3 — Deploy AWS Infrastructure (AMP, IAM, EKS)

```bash
./deploy-aws-env.sh
```