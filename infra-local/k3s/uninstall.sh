#!/bin/bash

NAMESPACE=monitoring

helm uninstall promtail -n $NAMESPACE || true
helm uninstall loki -n $NAMESPACE || true
helm uninstall kube-prometheus-stack -n $NAMESPACE || true
kubectl delete ns $NAMESPACE || true
echo "==> Done"