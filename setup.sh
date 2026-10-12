#!/bin/bash

## Install istio
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace
helm install istiod istio/istiod -n istio-system \
 -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/istiod-values.yaml \
 --wait

## Apply mesh telemetry
kubectl apply -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/mesh-telemetry.yaml

## Tag namespace
kubectl label namespace default istio-injection=enabled

## Deploy Tempo
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update
helm install tempo grafana-community/tempo -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/tempo-values.yaml \
 -n observability --create-namespace

## Deploy Loki
helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm
helm repo update
helm install local-s3 seaweedfs/seaweedfs \
  --namespace observability \
  --create-namespace \
  --set master.volumeSizeLimitMB=1024 \
  --set volume.fileSizeLimitMB=256 \
  --set s3.enabled=true

helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update
helm install loki grafana-community/loki \
 -n observability --create-namespace \
 -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/loki-values.yaml

## Deploy OTEL collector
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm install my-opentelemetry-collector \
  open-telemetry/opentelemetry-collector \
  -n observability --create-namespace \
  -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/otel-values.yaml

## Deploy Fluent-bit
helm repo add fluent https://fluent.github.io/helm-charts/
helm repo update
helm upgrade --install fluent-bit fluent/fluent-bit \
 --create-namespace --namespace observability \
 -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/fluent-bit-values.yaml

## Deploy application
kubectl apply -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/kubernetes-manifests.yaml

## Deploy Prometheus and Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n observability --create-namespace \
  -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/prometheus-values.yaml