#!/bin/bash

set -euo pipefail

#############################################
# Required Environment Variables
#############################################

: "${FALCON_CID:?Please export FALCON_CID}"
: "${FALCON_CLIENT_ID:?Please export FALCON_CLIENT_ID}"
: "${FALCON_CLIENT_SECRET:?Please export FALCON_CLIENT_SECRET}"
: "${REGISTRY_TOKEN:?Please export REGISTRY_TOKEN}"
: "${CLUSTER_NAME:?Please export CLUSTER_NAME}"

RELEASE_NAME="falcon-platform"
NAMESPACE="falcon-platform"
REGION="us-2"


#############################################
# Check prerequisites
#############################################

echo "Checking prerequisites..."

for cmd in kubectl helm jq base64 ./falcon-container-sensor-pull.sh; do
    if ! command -v ${cmd%% *} >/dev/null 2>&1; then
        echo "$cmd not found."
        exit 1
    fi
done

#############################################
# Get Sensor Image
#############################################

echo "Getting Falcon Sensor image..."

SENSOR_IMAGE=$(./falcon-container-sensor-pull.sh \
    -u "$FALCON_CLIENT_ID" \
    -s "$FALCON_CLIENT_SECRET" \
    -r "$REGION" \
    -t falcon-sensor \
    --get-image-path)

SENSOR_REPOSITORY="${SENSOR_IMAGE%:*}"
SENSOR_TAG="${SENSOR_IMAGE##*:}"

#############################################
# Get KAC Image
#############################################

echo "Getting Falcon KAC image..."

KAC_IMAGE=$(./falcon-container-sensor-pull.sh \
    -u "$FALCON_CLIENT_ID" \
    -s "$FALCON_CLIENT_SECRET" \
    -r "$REGION" \
    -t falcon-kac \
    --get-image-path)

KAC_REPOSITORY="${KAC_IMAGE%:*}"
KAC_TAG="${KAC_IMAGE##*:}"

#############################################
# Get Image Analyzer Image
#############################################

echo "Getting Falcon Image Analyzer image..."

IAR_IMAGE=$(./falcon-container-sensor-pull.sh \
    -u "$FALCON_CLIENT_ID" \
    -s "$FALCON_CLIENT_SECRET" \
    -r "$REGION" \
    -t falcon-imageanalyzer \
    --get-image-path)

IAR_REPOSITORY="${IAR_IMAGE%:*}"
IAR_TAG="${IAR_IMAGE##*:}"

#############################################
# Build Docker Config JSON
#############################################

echo "Building registry credentials..."

AUTH=$(printf "oauth2accesstoken:%s" "$REGISTRY_TOKEN" | base64 | tr -d '\n')

DOCKER_CONFIG=$(cat <<EOF
{
  "auths": {
    "registry.crowdstrike.com": {
      "username": "oauth2accesstoken",
      "password": "$REGISTRY_TOKEN",
      "auth": "$AUTH"
    }
  }
}
EOF
)

ENCODED_DOCKER_CONFIG=$(echo -n "$DOCKER_CONFIG" | base64 | tr -d '\n')

#############################################
# Install Helm Repo
#############################################

helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm >/dev/null 2>&1 || true
helm repo update

#############################################
# Deploy Falcon Platform
#############################################

echo "Deploying Falcon Platform..."

helm upgrade --install ${RELEASE_NAME} crowdstrike/falcon-platform \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --set createComponentNamespaces=true \
    \
    --set global.falcon.cid="${FALCON_CID}" \
    --set global.containerRegistry.configJSON="${ENCODED_DOCKER_CONFIG}" \
    \
    --set falcon-sensor.enabled=true \
    --set falcon-sensor.node.enabled=false \
    --set falcon-sensor.container.enabled=false \
    --set falcon-sensor.node.image.repository="${SENSOR_REPOSITORY}" \
    --set falcon-sensor.node.image.tag="${SENSOR_TAG}" \
    \
    --set falcon-kac.enabled=true \
    --set falcon-kac.image.repository="${KAC_REPOSITORY}" \
    --set falcon-kac.image.tag="${KAC_TAG}" \
    \
    --set falcon-image-analyzer.enabled=true \
    --set falcon-image-analyzer.deployment.enabled=true \
    --set falcon-image-analyzer.image.repository="${IAR_REPOSITORY}" \
    --set falcon-image-analyzer.image.tag="${IAR_TAG}" \
    --set falcon-image-analyzer.crowdstrikeConfig.clusterName="${CLUSTER_NAME}" \
    --set falcon-image-analyzer.crowdstrikeConfig.clientID="${FALCON_CLIENT_ID}" \
    --set falcon-image-analyzer.crowdstrikeConfig.clientSecret="${FALCON_CLIENT_SECRET}"

#############################################
# Verify Deployment
#############################################

echo
echo "Waiting for components to start..."
sleep 30

echo
echo "Helm Release"
helm list -n ${NAMESPACE}

echo
echo "Falcon Pods"
kubectl get pods -A -l app.kubernetes.io/instance=${RELEASE_NAME}

echo
echo "Sensor"
kubectl get daemonset,pods -n falcon-system

echo
echo "KAC"
kubectl get deployment,pods -n falcon-kac

echo
echo "Image Analyzer"
kubectl get deployment,pods -n falcon-image-analyzer

echo
echo "Falcon Platform deployment completed successfully."
