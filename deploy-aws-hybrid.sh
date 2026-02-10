#!/bin/bash
set -euo pipefail

NAMESPACE_APP="riddlebuddy"
RELEASE_APP="riddlebuddy"


echo "🔎 Checking required environment variables..."

if [ -z "$DEEPSEEK_API_KEY" ]; then
echo "❌ DEEPSEEK_API_KEY is not set"
  exit 1
fi

echo "✅ Environment OK"

echo "📦 Creating namespaces if not exist..."
kubectl create namespace $NAMESPACE_APP --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Deploying RiddleBuddy app (Helm)..."
helm upgrade --install $RELEASE_APP \
  ./helm/riddlebuddy \
  -n $NAMESPACE_APP \
  --set secrets.deepseekApiKey="$DEEPSEEK_API_KEY"

echo "  kubectl get pods -n $NAMESPACE_APP"
