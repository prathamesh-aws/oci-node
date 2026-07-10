#!/bin/bash

set -euo pipefail

#############################################
# Required Environment Variables
#############################################

: "${FALCON_CID:?Please export FALCON_CID}"
: "${FALCON_CLIENT_ID:?Please export FALCON_CLIENT_ID}"
: "${FALCON_CLIENT_SECRET:?Please export FALCON_CLIENT_SECRET}"
: "${REGISTRY_TOKEN:?Please export REGISTRY_TOKEN}"

REGION="us-2"
RELEASE="falcon-platform"
NAMESPACE="falcon-platform"

#############################################
# Get Falcon Container Sensor Image
#############################################

echo "Getting Falcon Container Sensor image..."

IMAGE=$(./falcon-container-sensor-pull.sh \
    -u "$FALCON_CLIENT_ID" \
    -s "$FALCON_CLIENT_SECRET" \
    -r "$REGION" \
    -t falcon-container \
    --get-image-path)

IMAGE_REPOSITORY="${IMAGE%:*}"
IMAGE_TAG="${IMAGE##*:}"

echo "Repository : ${IMAGE_REPOSITORY}"
echo "Tag        : ${IMAGE_TAG}"

#############################################
# Create Docker Config
#############################################

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

helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || true
helm repo update

#############################################
# Deploy
#############################################

helm upgrade --install ${RELEASE} crowdstrike/falcon-platform \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --set createComponentNamespaces=true \
    \
    --set global.falcon.cid="${FALCON_CID}" \
    --set global.containerRegistry.configJSON="${ENCODED_DOCKER_CONFIG}" \
    \
    --set falcon-sensor.enabled=true \
    --set falcon-sensor.node.enabled=false \
    \
    --set falcon-sensor.container.enabled=true \
    --set falcon-sensor.container.image.repository="${IMAGE_REPOSITORY}" \
    --set falcon-sensor.container.image.tag="${IMAGE_TAG}" \
    \
    --set falcon-sensor.container.image.pullSecrets.enable=true \
    --set falcon-sensor.container.image.pullSecrets.allNamespaces=true \
    \
    --set falcon-kac.enabled=false \
    --set falcon-image-analyzer.enabled=false

echo "Deployment completed."
