#!/bin/bash

## Install istio
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace
helm install istiod istio/istiod -n istio-system --wait

## Tag namespace
kubectl label namespace default istio-injection=enabled

## Deploy OTEL collector
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm install my-opentelemetry-collector \
  open-telemetry/opentelemetry-collector \
  -f otel-values.yaml

## Deploy application
kubectl apply -f https://raw.githubusercontent.com/phongtr27/microservices-demo/refs/heads/main/kubernetes-manifests.yaml