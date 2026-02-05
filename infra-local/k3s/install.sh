#!/bin/bash
set -e

NAMESPACE=monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create ns $NAMESPACE || true

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
  -f infra-local/k3s/prometheus/values.yaml

echo "📈 Deploying Grafana..."
kubectl apply -f infra-local/k3s/grafana/dashboard-cm.yaml
helm upgrade --install $RELEASE_GRAFANA grafana/grafana \
  -n $NAMESPACE_MON \
  -f infra-local/k3s/grafana/values.yaml
