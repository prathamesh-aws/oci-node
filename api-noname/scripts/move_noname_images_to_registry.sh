#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'
TIME_FORMAT="+%F %H:%M:%S"

function check_value {
  local key=$1
  local value=$2
  if [[ "$value" == *"\{\{"*"\}\}"* ]] || [[ -z "$value" ]]; then
    printf "$(date "$TIME_FORMAT") - ${RED}[ERROR]${NC}: Value for ${key} not provided or not replaced!\n"
    exit 2
  fi
}

DOCKER_REGISTRY="jfrog.cicd.nonamesec.com/nns-docker"
DOCKER_USER="training@nonamesecurity.com"
DOCKER_PASSWORD="eyJ2ZXIiOiIyIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYiLCJraWQiOiJoblh5eWFzX0k1bWFUN2ZtU0w5YkFyMmluZlN3cHVibGpXUEFjeENMNEdFIn0.eyJzdWIiOiJqZnJ0QDAxZzVyenMxNDhyeXliMW1iZGNxeTAwdjcwL3VzZXJzL3RyYWluaW5nQG5vbmFtZXNlY3VyaXR5LmNvbSIsInNjcCI6Im1lbWJlci1vZi1ncm91cHM6aW5zdGFsbGVyIiwiYXVkIjoiamZydEAwMWc1cnpzMTQ4cnl5YjFtYmRjcXkwMHY3MCIsImlzcyI6ImpmcnRAMDFnNXJ6czE0OHJ5eWIxbWJkY3F5MDB2NzAvdXNlcnMvZGV2b3BzQG5vbmFtZXNlY3VyaXR5LmNvbSIsImlhdCI6MTcyNTY1MTc1MCwianRpIjoiYWMxMDU0ZjUtMzM1OC00M2EyLWFiNGQtYzExOGJhNWM5ZjA3In0.dtWi_XbqJjLciQgvEt8KTyhmXXxi7J1mTQPD6FvnfCTidFWLiTLGy22CA7IzAuRxlOEGEWaafWycdSDczjD26EseKNSTKvT4jP4-auY9UThx0bvIVIlyabQp-rbNz51cGX-3NlYEhR1cSG1BX_vfiaOoXqv4jmVTvG5-L08iiJbDuAFvt8zEWXrz0OYOWltanuFPnGv_YFiX396eXmI7U6MnJAmrF3QfExc_g85hpBO2kPiodCUepkhd7LkToIpRSyFL-QEpNwy3yAlmEEFLEZz4uDTj1XlW9c1LHcy-6wLW3u9VHVzpGFGFgE2UiundMvuvWMrMjsFjr54_2FEgLg"

check_value "JFROG_REGISTRY" "$DOCKER_REGISTRY"
check_value "DOCKER_USER" "$DOCKER_USER"
check_value "DOCKER_PASSWORD" "$DOCKER_PASSWORD"

[[ -z "$1" ]] && printf "$(date "$TIME_FORMAT") - ${RED}[ERROR]${NC}: Please provide your docker registry (i.e. jfrog.cicd.nonamesec.com/noname-docker-release)\n" && exit 5
CUSTOMER_DOCKER_REGISTRY=$1

ERROR_MSG=$(docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORD" "$DOCKER_REGISTRY" 2>&1)
if [ $? -ne 0 ]; then
    echo "Docker login failed with the following error:"
    echo "$ERROR_MSG"
    exit 1
fi


services=("noname-remote-operator" "noname-sensor" "noname-kubernetes-posture")
tags=("remote-operator-1.0.13" "3.3.29" "v1.0.4")

for index in "${!services[@]}"
do
  service=${services[$index]}
  DOCKER_TAG=${tags[$index]}

  check_value "$service" "$DOCKER_TAG"

  image="${service}:${DOCKER_TAG}"
  full_image="${DOCKER_REGISTRY}/${image}"
  echo "Pulling docker image: ${full_image}"
  docker pull ${full_image}

  if [[ -n $CUSTOMER_DOCKER_REGISTRY ]] ; then
    new_tag="$CUSTOMER_DOCKER_REGISTRY/${image}"
    docker tag ${full_image} ${new_tag}
    echo "Pushing docker image: ${new_tag}"
    docker push ${new_tag}
  fi
done
