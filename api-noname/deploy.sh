#!/usr/bin/env bash
set -e

namespace="noname-security"

deploy_order=(
"templates/operator_service_account.yml"
"templates/posture_cluster_role.yml"
"templates/operator_cluster_role.yml"
"templates/operator_role.yml"
"templates/operator_role_binding.yml"
"templates/operator_deployment.yml"
)

if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
  kubectl create namespace "$namespace"
fi

./create_secret_credentials.sh

for yaml_path in "${deploy_order[@]}"; do
  kubectl apply -f "$yaml_path"
done
