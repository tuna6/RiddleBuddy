#!/bin/bash
set -euo pipefail

ROOT_DIR=$(pwd)

echo "🚀 RiddleBuddy Full Stack Startup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─────────────────────────────────────────────
# 1. PREFLIGHT CHECKS
# ─────────────────────────────────────────────
echo "🔎 Checking required environment variables..."
[[ -z "${DEEPSEEK_API_KEY:-}" ]] && { echo "❌ DEEPSEEK_API_KEY is not set"; exit 1; }
[[ -z "$HOSTED_ZONE_ID" ]]      && { echo "❌ HOSTED_ZONE_ID is not set";    exit 1; }
echo "✅ Environment OK"

# ─────────────────────────────────────────────
# 2. TERRAFORM — network + monitoring first
#    VPC, subnets, Grafana EC2, AMP, etc.
# ─────────────────────────────────────────────
echo ""
echo "🌍 Provisioning network + monitoring stack..."
cd "$ROOT_DIR/infra-cloud/hybrid-aws/terraform/aws"
terraform init
terraform apply -auto-approve
echo "✅ Network + monitoring stack provisioned"

# ─────────────────────────────────────────────
# 3. TERRAFORM — EKS
#    EKS depends on VPC/subnets from step 2
# ─────────────────────────────────────────────
echo ""
echo "☸️  Provisioning EKS cluster..."
cd "$ROOT_DIR/infra-cloud/eks/dev"
terraform init
terraform apply -auto-approve
echo "✅ EKS cluster provisioned"

# ─────────────────────────────────────────────
# 4. DEPLOY RIDDLEBUDDY
#    Switch kubectl context + deploy all services
# ─────────────────────────────────────────────
echo ""
cd "$ROOT_DIR"
bash deploy-app-eks.sh

