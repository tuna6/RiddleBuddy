#!/bin/bash
set -euo pipefail

NAMESPACE_INGRESS="ingress-nginx"
RELEASE_INGRESS="ingress-nginx"
ROOT_DIR=$(pwd)

HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
DOMAIN="${DOMAIN:-riddlebuddy.nguyentu.online}"
CLOUDFRONT_DOMAIN="d3ttg4n9hc3nat.cloudfront.net"
CLOUDFRONT_HOSTED_ZONE_ID="Z2FDTNDATAQYW2"   # fixed AWS value for all CloudFront distributions
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-}"

echo "⚠️  WARNING: This will destroy the NLB and ALL infrastructure."
if [[ -z "${CI:-}" ]]; then
  read -p "Are you sure? (yes/no): " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Aborted."
    exit 1
  fi
else
  echo "⚠️  Running in CI — skipping confirmation prompt"
fi

# ─────────────────────────────────────────────
# PREFLIGHT
# ─────────────────────────────────────────────
[[ -z "$HOSTED_ZONE_ID" ]] && { echo "❌ HOSTED_ZONE_ID is not set"; exit 1; }

echo "✅ CloudFront domain: $CLOUDFRONT_DOMAIN"

# ─────────────────────────────────────────────
# 1. SWITCH CONTEXT TO EKS
# ─────────────────────────────────────────────
echo ""
echo "🔄 Switching kubectl context to EKS..."
aws eks update-kubeconfig --region ap-southeast-1 --name riddlebuddy-eks
echo "✅ kubectl connected to: $(kubectl config current-context)"

# ─────────────────────────────────────────────
# 2. ROUTE53 → CLOUDFRONT (before NLB is gone)
# ─────────────────────────────────────────────
echo ""
echo "📡 Pointing Route53 → CloudFront before teardown..."

CHANGE_ID=$(aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "{
    \"Comment\": \"Teardown: switch $DOMAIN from NLB to CloudFront\",
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$DOMAIN\",
        \"Type\": \"A\",
        \"AliasTarget\": {
          \"HostedZoneId\": \"$CLOUDFRONT_HOSTED_ZONE_ID\",
          \"DNSName\": \"$CLOUDFRONT_DOMAIN\",
          \"EvaluateTargetHealth\": false
        }
      }
    }]
  }" \
  --query 'ChangeInfo.Id' --output text)

echo "⏳ Waiting for Route53 propagation..."
aws route53 wait resource-record-sets-changed --id "$CHANGE_ID"
echo "✅ Route53 updated: $DOMAIN → $CLOUDFRONT_DOMAIN"

# ─────────────────────────────────────────────
# 3. UNINSTALL NGINX INGRESS → destroys NLB
#    MUST be done before terraform destroy
#    otherwise NLB gets orphaned and keeps billing
# ─────────────────────────────────────────────
echo ""
echo "🗑️  Uninstalling NGINX Ingress Controller (destroys NLB)..."
helm uninstall $RELEASE_INGRESS -n $NAMESPACE_INGRESS || echo "⚠️  NGINX Ingress not found, skipping..."

echo "⏳ Waiting for NLB to be fully deleted (2-3 min)..."
for i in $(seq 1 18); do
  NLB=$(kubectl get svc -n $NAMESPACE_INGRESS 2>/dev/null | grep LoadBalancer || true)
  if [ -z "$NLB" ]; then
    echo "✅ NLB deleted"
    break
  fi
  echo "   ... still waiting ($((i*10))s)"
  sleep 10
done

# ─────────────────────────────────────────────
# 4. TERRAFORM DESTROY — EKS first
# ─────────────────────────────────────────────
echo ""
echo "💣 Destroying EKS cluster..."
cd "$ROOT_DIR/infra-cloud/eks/dev"
terraform init
terraform destroy -auto-approve || true
echo "✅ EKS cluster destroyed"

# ─────────────────────────────────────────────
# 5. TERRAFORM DESTROY — network + monitoring last
# ─────────────────────────────────────────────
echo ""
echo "💣 Destroying network + monitoring stack..."
cd "$ROOT_DIR/infra-cloud/hybrid-aws/terraform/aws"
terraform init
terraform destroy -auto-approve \
  -var="allowed_ip=0.0.0.0/0" \
  -var="project_name=riddlebuddy-hybrid" \
  -var="region=ap-southeast-1" \
  -var="key_name=riddlebuddy-monitoring-key" \
  -var="grafana_admin_password=$GRAFANA_ADMIN_PASSWORD"
  echo "✅ Network + monitoring stack destroyed"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL RESOURCES DESTROYED SUCCESSFULLY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🌐 $DOMAIN now serves via CloudFront"
echo ""
echo "💡 Double check in AWS console:"
echo "   - EC2 → Load Balancers  (no orphaned NLB)"
echo "   - EKS → Clusters        (no riddlebuddy-eks)"
echo "   - VPC → Your VPCs       (no riddlebuddy VPC)"
