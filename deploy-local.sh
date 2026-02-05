#!/bin/bash
set -euo pipefail

NAMESPACE_APP="riddlebuddy"
NAMESPACE_MON="monitoring"

RELEASE_APP="riddlebuddy"
RELEASE_LOKI="loki"
RELEASE_GRAFANA="grafana"

echo "🔎 Checking required environment variables..."

if [ -z "$DEEPSEEK_API_KEY" ]; then
  echo "❌ DEEPSEEK_API_KEY is not set"
  exit 1
fi

echo "✅ Environment OK"

echo "📦 Creating namespaces if not exist..."
kubectl create namespace $NAMESPACE_APP --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_MON --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Deploying RiddleBuddy app (Helm)..."
helm upgrade --install $RELEASE_APP \
  ./helm/riddlebuddy \
  -n $NAMESPACE_APP \
  --set secrets.deepseekApiKey="$DEEPSEEK_API_KEY"

echo "📊 Deploying Loki..."
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

helm upgrade --install $RELEASE_LOKI grafana/loki \
  -n $NAMESPACE_MON \
  -f infra-local/k3s/loki/values.yaml

echo "==> Install Promtail"
helm upgrade --install promtail \
  grafana/promtail \
  -n $NAMESPACE_MON \
  -f infra-local/k3s/promtail/values.yaml

echo "📈 Deploying  Prometheus"
helm upgrade --install prometheus prometheus-community/prometheus \
  -n $NAMESPACE_MON \
  -f prometheus/values.yaml

echo "📈 Deploying Grafana..."
helm upgrade --install $RELEASE_GRAFANA grafana/grafana \
  -n $NAMESPACE_MON \
  -f grafana/values.yaml

echo "✅ All components deployed successfully!"
echo ""
echo "🔍 Useful commands:"
echo "  kubectl get pods -n $NAMESPACE_APP"
echo "  kubectl get pods -n $NAMESPACE_MON"
echo "  kubectl port-forward svc/grafana 3000:80 -n $NAMESPACE_MON"
