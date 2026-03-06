#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-jenkins-kube}"
REGISTRY_NAME="${REGISTRY_NAME:-kind-registry}"
REGISTRY_PORT="${REGISTRY_PORT:-5001}"
KIND_NODE_IMAGE="${KIND_NODE_IMAGE:-kindest/node:v1.30.8}"
JENKINS_NAME="${JENKINS_NAME:-local-jenkins}"
JENKINS_HTTP_PORT="${JENKINS_HTTP_PORT:-8081}"
JENKINS_AGENT_PORT="${JENKINS_AGENT_PORT:-50000}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-$HOME/.kube/config}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

require_cmd docker
require_cmd kind
require_cmd kubectl

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  echo "Kubeconfig not found at: $KUBECONFIG_PATH"
  echo "It will be created after cluster setup if you are using kind defaults."
fi

if ! docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
  docker run -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "$REGISTRY_NAME" registry:2
fi

if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  cfg_file="$(mktemp)"
  cat > "$cfg_file" <<CFG
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
    endpoint = ["http://${REGISTRY_NAME}:5000"]
nodes:
- role: control-plane
CFG
  kind create cluster --name "$CLUSTER_NAME" --config "$cfg_file" --image "$KIND_NODE_IMAGE"
  rm -f "$cfg_file"
fi

docker network connect kind "$REGISTRY_NAME" >/dev/null 2>&1 || true

kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

cat <<EOF_CM | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF_CM

docker build -t local/jenkins-kind:latest -f jenkins/Dockerfile .

if docker inspect "$JENKINS_NAME" >/dev/null 2>&1; then
  docker rm -f "$JENKINS_NAME" >/dev/null
fi

docker run -d \
  --restart unless-stopped \
  --name "$JENKINS_NAME" \
  -u root \
  -p "${JENKINS_HTTP_PORT}:8080" \
  -p "${JENKINS_AGENT_PORT}:50000" \
  -e KUBECONFIG=/root/.kube/config \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  -v "$WORKSPACE_DIR":/workspace \
  -v "$HOME/.kube":/root/.kube:ro \
  local/jenkins-kind:latest

echo

echo "Cluster context: kind-${CLUSTER_NAME}"
echo "Kind node image: ${KIND_NODE_IMAGE}"
echo "Local registry: localhost:${REGISTRY_PORT}"
echo "Jenkins URL: http://localhost:${JENKINS_HTTP_PORT}"
echo "Workspace mount in Jenkins container: /workspace"
echo

echo "To get Jenkins initial admin password:"
echo "  docker exec ${JENKINS_NAME} cat /var/jenkins_home/secrets/initialAdminPassword"
