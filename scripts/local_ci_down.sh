#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-jenkins-kube}"
REGISTRY_NAME="${REGISTRY_NAME:-kind-registry}"
JENKINS_NAME="${JENKINS_NAME:-local-jenkins}"

if docker inspect "$JENKINS_NAME" >/dev/null 2>&1; then
  docker rm -f "$JENKINS_NAME" >/dev/null
fi

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  kind delete cluster --name "$CLUSTER_NAME"
fi

if docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
  docker rm -f "$REGISTRY_NAME" >/dev/null
fi

echo "Local CI stack removed (${CLUSTER_NAME}, ${REGISTRY_NAME}, ${JENKINS_NAME})."
