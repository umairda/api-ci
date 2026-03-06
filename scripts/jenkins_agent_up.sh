#!/usr/bin/env bash
set -euo pipefail

AGENT_IMAGE="${AGENT_IMAGE:-local/jenkins-agent:latest}"
AGENT_NAME="${AGENT_NAME:-local-agent}"
AGENT_CONTAINER_NAME="${AGENT_CONTAINER_NAME:-local-jenkins-agent}"
JENKINS_URL="${JENKINS_URL:-http://host.docker.internal:8081}"
JENKINS_SECRET="${JENKINS_SECRET:-}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"
DOCKER_SOCK="${DOCKER_SOCK:-}"

if [[ -z "$JENKINS_SECRET" ]]; then
  echo "JENKINS_SECRET is required."
  echo "Create node '${AGENT_NAME}' in Jenkins with launch method 'Launch agent by connecting it to the controller'."
  echo "Then copy the secret from the node page and run:"
  echo "  JENKINS_SECRET=<secret> make jenkins-agent-up"
  exit 1
fi

if [[ -z "$DOCKER_SOCK" ]]; then
  if [[ -S "/var/run/docker.sock" ]]; then
    DOCKER_SOCK="/var/run/docker.sock"
  elif [[ -S "${HOME}/.docker/run/docker.sock" ]]; then
    DOCKER_SOCK="${HOME}/.docker/run/docker.sock"
  else
    echo "Docker socket not found. Set DOCKER_SOCK explicitly."
    exit 1
  fi
fi

DOCKER_GID="${DOCKER_GID:-}"
if [[ -z "$DOCKER_GID" ]]; then
  DOCKER_GID="$(stat -c '%g' "$DOCKER_SOCK" 2>/dev/null || stat -f '%g' "$DOCKER_SOCK")"
fi
DOCKER_ROOT_GID="${DOCKER_ROOT_GID:-0}"

GROUP_ARGS=(--group-add "$DOCKER_GID")
if [[ "$DOCKER_GID" != "$DOCKER_ROOT_GID" ]]; then
  GROUP_ARGS+=(--group-add "$DOCKER_ROOT_GID")
fi

docker build -t "$AGENT_IMAGE" -f jenkins/agent.Dockerfile .

docker rm -f "$AGENT_CONTAINER_NAME" >/dev/null 2>&1 || true

docker run -d \
  --restart unless-stopped \
  --name "$AGENT_CONTAINER_NAME" \
  -e JENKINS_URL="$JENKINS_URL" \
  -e JENKINS_SECRET="$JENKINS_SECRET" \
  -e JENKINS_AGENT_NAME="$AGENT_NAME" \
  -e JENKINS_WEB_SOCKET=true \
  "${GROUP_ARGS[@]}" \
  -v "$DOCKER_SOCK":/var/run/docker.sock \
  -v "$WORKSPACE_DIR":/workspace \
  -v "$HOME/.kube":/home/jenkins/.kube:ro \
  "$AGENT_IMAGE"

echo "Started Jenkins agent '${AGENT_NAME}' as container '${AGENT_CONTAINER_NAME}'."
