#!/bin/bash
set -euo pipefail

NAMESPACE_APP="riddlebuddy"
NAMESPACE_INGRESS="ingress-nginx"
RELEASE_APP="riddlebuddy"
RELEASE_INGRESS="ingress-nginx"

HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"      # e.g. Z0123456789ABC
DOMAIN="${DOMAIN:-riddlebuddy.nguyentu.online}"
AWS_REGION="ap-southeast-1"
EKS_CLUSTER="riddlebuddy-eks"
ACM_CERT_ARN="${ACM_CERT_ARN:-}"  # e.g. arn:aws:acm:ap-southeast-1:123456789012:certificate/abcdefg-1234-5678-abcd-1234567890ab

# ─────────────────────────────────────────────
# 1. PREFLIGHT CHECKS
# ─────────────────────────────────────────────
echo "🔎 Checking required environment variables..."
[[ -z "${DEEPSEEK_API_KEY:-}" ]] && { echo "❌ DEEPSEEK_API_KEY is not set"; exit 1; }
[[ -z "$HOSTED_ZONE_ID" ]]      && { echo "❌ HOSTED_ZONE_ID is not set";    exit 1; }
echo "✅ Environment OK"

aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER

echo "🔎 Checking kubectl connectivity..."
kubectl cluster-info --request-timeout=5s > /dev/null

# ─────────────────────────────────────────────
# 2. NAMESPACES
# ─────────────────────────────────────────────
echo ""
echo "📦 Creating namespaces..."
kubectl create namespace $NAMESPACE_APP     --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_INGRESS --dry-run=client -o yaml | kubectl apply -f -

# ─────────────────────────────────────────────
# 3. DEPLOY kube-state-metrics
# ─────────────────────────────────────────────
echo ""
echo "🚀 Deploying kube-state-metrics..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
  -n kube-system \
  --wait --timeout=5m
echo "✅ kube-state-metrics deployed"
# ─────────────────────────────────────────────
# 4. NGINX INGRESS CONTROLLER
# ─────────────────────────────────────────────
echo ""
echo "🌐 Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo update

helm upgrade --install $RELEASE_INGRESS ingress-nginx/ingress-nginx \
  -n $NAMESPACE_INGRESS \
  -f helm/riddlebuddy/ingress-nginx-values.yaml \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="$ACM_CERT_ARN" \
  --wait --timeout=5m

echo "✅ NGINX Ingress Controller deployed"

# ─────────────────────────────────────────────
# 5. DEPLOY RIDDLEBUDDY
# ─────────────────────────────────────────────
echo ""
echo "🚀 Deploying RiddleBuddy..."
helm upgrade --install $RELEASE_APP \
  ./helm/riddlebuddy \
  -n $NAMESPACE_APP \
  --set api.image.repository="${ECR_REGISTRY}/riddlebuddy" \
  --set feedback.image.repository="${ECR_REGISTRY}/riddlebuddy-feedback" \
  --set secrets.deepseekApiKey="${DEEPSEEK_API_KEY}" \
  --wait --timeout=5m

echo "✅ RiddleBuddy deployed"

# ─────────────────────────────────────────────
# 6. INSTALL ARGOCD
# ─────────────────────────────────────────────
echo ""
echo "🚀 Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  --server-side

echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd --timeout=120s

echo "📋 Applying ArgoCD app and ingress..."
kubectl apply -f argocd/argocd-app.yaml
kubectl apply -f argocd/argocd-ingress.yaml
echo "✅ ArgoCD installed"

# ─────────────────────────────────────────────
# 7. GET LOAD BALANCER HOSTNAME
# ─────────────────────────────────────────────
echo ""
echo "⏳ Waiting for NLB hostname (can take 2-3 min)..."
LB_HOST=""
for i in $(seq 1 18); do
  LB_HOST=$(kubectl get svc ingress-nginx-controller \
    -n $NAMESPACE_INGRESS \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  [[ -n "$LB_HOST" ]] && break
  echo "   ... still waiting ($((i*10))s)"
  sleep 10
done

if [[ -z "$LB_HOST" ]]; then
  echo "❌ NLB hostname not ready after 3 min. Check manually:"
  echo "   kubectl get svc ingress-nginx-controller -n $NAMESPACE_INGRESS"
  exit 1
fi
echo "✅ NLB hostname: $LB_HOST"

# ─────────────────────────────────────────────
# 7. UPDATE ROUTE53
# ─────────────────────────────────────────────
echo ""
echo "📡 Updating Route53: $DOMAIN → $LB_HOST"
ALB_HOSTED_ZONE_ID=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='${LB_HOST}'].CanonicalHostedZoneId" \
  --output text)
CHANGE_ID=$(aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "{
    \"Comment\": \"Updated by deploy-local-app.sh\",
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$DOMAIN\",
        \"Type\": \"A\",
        \"AliasTarget\": {
          \"HostedZoneId\": \"$ALB_HOSTED_ZONE_ID\",
          \"DNSName\": \"$LB_HOST\",
          \"EvaluateTargetHealth\": true
        }
      }
    }]
  }" \
  --query 'ChangeInfo.Id' --output text)
echo "✅ Route53 updated"

echo "📡 Updating Route53: argocd.nguyentu.online → $LB_HOST"
aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"argocd.nguyentu.online\",
        \"Type\": \"A\",
        \"AliasTarget\": {
          \"HostedZoneId\": \"$ALB_HOSTED_ZONE_ID\",
          \"DNSName\": \"$LB_HOST\",
          \"EvaluateTargetHealth\": true
        }
      }
    }]
  }"
echo "✅ ArgoCD Route53 updated"
echo "⏳ Waiting for Route53 propagation..."
aws route53 wait resource-record-sets-changed --id "$CHANGE_ID"

# ─────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL DONE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🌐 https://$DOMAIN"
echo "   🔗 NLB: $LB_HOST"
echo ""
echo "🔍 Useful commands:"
echo "   kubectl get pods    -n $NAMESPACE_APP"
echo "   kubectl get ingress -n $NAMESPACE_APP"
echo "   kubectl get svc     -n $NAMESPACE_INGRESS"
