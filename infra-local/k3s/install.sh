#!/bin/bash
set -e

NAMESPACE=monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create ns $NAMESPACE || true

echo "==> Install Prometheus + Grafana"
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  -n $NAMESPACE \
  -f prometheus-values.yaml

echo "==> Install Loki (SingleBinary)"
helm upgrade --install loki \
  grafana/loki \
  -n $NAMESPACE \
  -f loki/loki-values.yaml

echo "==> Install Promtail"
helm upgrade --install promtail \
  grafana/promtail \
  -n $NAMESPACE

echo "==> Done"
