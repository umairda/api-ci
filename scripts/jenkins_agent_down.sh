#!/usr/bin/env bash
set -euo pipefail

AGENT_CONTAINER_NAME="${AGENT_CONTAINER_NAME:-local-jenkins-agent}"
docker rm -f "$AGENT_CONTAINER_NAME" >/dev/null 2>&1 || true
echo "Stopped Jenkins agent container: $AGENT_CONTAINER_NAME"
