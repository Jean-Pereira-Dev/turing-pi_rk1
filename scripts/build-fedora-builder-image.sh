#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEDORA_VERSION="${FEDORA_VERSION:-43}"
FEDORA_BUILDER_IMAGE="${FEDORA_BUILDER_IMAGE:-turing-rk1-fedora-builder:fedora${FEDORA_VERSION}}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-${ROOT_DIR}/docker/fedora/Dockerfile}"

if docker ps >/dev/null 2>&1; then
  run_docker() { docker "$@"; }
elif sg docker -c 'docker ps >/dev/null 2>&1' 2>/dev/null; then
  run_docker() { sg docker -c "docker $*"; }
elif sudo -n docker ps >/dev/null 2>&1; then
  run_docker() { sudo docker "$@"; }
else
  echo "ERROR: Docker is not accessible." >&2
  echo "Run: sudo usermod -aG docker \$USER && newgrp docker" >&2
  exit 1
fi

echo "==> Building Fedora builder image"
echo "==> Fedora version : ${FEDORA_VERSION}"
echo "==> Image tag      : ${FEDORA_BUILDER_IMAGE}"
echo "==> Dockerfile     : ${DOCKERFILE_PATH}"

run_docker build --pull \
  --build-arg FEDORA_VERSION="${FEDORA_VERSION}" \
  -t "${FEDORA_BUILDER_IMAGE}" \
  -f "${DOCKERFILE_PATH}" \
  "${ROOT_DIR}"
