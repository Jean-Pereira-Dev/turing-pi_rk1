#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Local kernel build for Turing Pi RK1.
#
# Self-contained: clones Armbian build framework, copies userpatches from this
# repo, and builds kernel .deb packages inside an Armbian Docker container.
# Mirrors the same logic the CI workflow uses against a local Fedora builder image.
#
# Environment variables (all optional):
#   WORKDIR               — build workspace on the host  (default: ~/local-kernel-build)
#   KERNEL_BRANCH         — Armbian kernel branch        (default: current)
#   ARMBIAN_REF           — Armbian ref/tag/SHA or latest (default: latest)
#   BUILD_TIMEOUT_MINUTES — per-attempt timeout          (default: 120)
#   ARMBIAN_DEPTH         — git clone depth for Armbian  (default: 1500)
#   KERNEL_GIT_MODE       — shallow or full              (default: shallow)
#   FEDORA_VERSION        — Fedora release for builder    (default: 43)
#   AUTO_BUILD_IMAGE      — build Fedora image if missing (default: yes)
#   ARMBIAN_IMAGE         — container image for builds    (default: local Fedora builder image)
#
# Usage:
#   scripts/build-kernel-local.sh
#   KERNEL_BRANCH=current BUILD_TIMEOUT_MINUTES=90 scripts/build-kernel-local.sh
# ---------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${WORKDIR:-$HOME/local-kernel-build}"
KERNEL_BRANCH="${KERNEL_BRANCH:-current}"
ARMBIAN_REF="${ARMBIAN_REF:-latest}"
BUILD_TIMEOUT_MINUTES="${BUILD_TIMEOUT_MINUTES:-120}"
ARMBIAN_DEPTH="${ARMBIAN_DEPTH:-1500}"
KERNEL_GIT_MODE="${KERNEL_GIT_MODE:-shallow}"
FEDORA_VERSION="${FEDORA_VERSION:-43}"
AUTO_BUILD_IMAGE="${AUTO_BUILD_IMAGE:-yes}"
ARMBIAN_IMAGE="${ARMBIAN_IMAGE:-turing-rk1-fedora-builder:fedora${FEDORA_VERSION}}"

# ---- Docker access --------------------------------------------------------
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

echo "==> Repo root       : ${ROOT_DIR}"
echo "==> Work dir        : ${WORKDIR}"
echo "==> Kernel branch   : ${KERNEL_BRANCH}"
echo "==> Armbian ref     : ${ARMBIAN_REF}"
echo "==> Build timeout   : ${BUILD_TIMEOUT_MINUTES}m"
echo "==> Armbian depth   : ${ARMBIAN_DEPTH}"
echo "==> Kernel git mode : ${KERNEL_GIT_MODE}"
echo "==> Docker image    : ${ARMBIAN_IMAGE}"

mkdir -p "${WORKDIR}"

if [ "${AUTO_BUILD_IMAGE}" = "yes" ] && ! run_docker image inspect "${ARMBIAN_IMAGE}" >/dev/null 2>&1; then
  echo "==> Builder image not found locally; building ${ARMBIAN_IMAGE}"
  FEDORA_VERSION="${FEDORA_VERSION}" \
  FEDORA_BUILDER_IMAGE="${ARMBIAN_IMAGE}" \
  "${ROOT_DIR}/scripts/build-fedora-builder-image.sh"
fi

# ---- Clone / update Armbian build framework -------------------------------
ARMBIAN_SRC="${WORKDIR}/armbian-build-src"
if [ "${ARMBIAN_REF}" = "latest" ]; then
  echo "==> Resolving latest Armbian release tag"
  ARMBIAN_REF="$(curl -fsSL https://api.github.com/repos/armbian/build/releases/latest \
    | python3 -c 'import sys, json; print(json.load(sys.stdin)["tag_name"])')"
  echo "==> Latest Armbian release: ${ARMBIAN_REF}"
fi

if [ -d "${ARMBIAN_SRC}/.git" ]; then
  echo "==> Updating existing Armbian clone at ${ARMBIAN_SRC}"
  git -C "${ARMBIAN_SRC}" fetch --depth="${ARMBIAN_DEPTH}" origin "${ARMBIAN_REF}"
  git -C "${ARMBIAN_SRC}" checkout -f FETCH_HEAD
else
  echo "==> Cloning Armbian build framework (depth=${ARMBIAN_DEPTH})"
  rm -rf "${ARMBIAN_SRC}"
  git clone --depth="${ARMBIAN_DEPTH}" https://github.com/armbian/build.git "${ARMBIAN_SRC}"
  git -C "${ARMBIAN_SRC}" fetch --depth="${ARMBIAN_DEPTH}" origin "${ARMBIAN_REF}"
  git -C "${ARMBIAN_SRC}" checkout -f FETCH_HEAD
fi

# ---- Register binfmt emulation -------------------------------------------
echo "==> Registering binfmt emulation"
run_docker run --privileged --rm tonistiigi/binfmt --install arm64,arm,riscv64 >/dev/null

# ---- Generate inner script ------------------------------------------------
INNER_SCRIPT="$(mktemp "${WORKDIR}/kernel-build-inner.XXXXXX.sh")"
cat > "${INNER_SCRIPT}" <<'INNEREOF'
set -euo pipefail
export COLUMNS=160
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

git config --global --add safe.directory '*'

echo "=== Step 1: Verify Fedora builder toolchain ==="
for tool in \
  dialog \
  dpkg \
  dpkg-architecture \
  fuser \
  git \
  curl \
  gawk \
  gpg \
  linux-version \
  locale-gen \
  uuidgen \
  aarch64-linux-gnu-gcc \
  arm-linux-gnueabi-gcc \
  qemu-aarch64-static; do
  command -v "${tool}" >/dev/null || { echo "ERROR: Missing required tool: ${tool}"; exit 1; }
done

KERNEL_BRANCH="${KERNEL_BRANCH:-current}"
BUILD_TIMEOUT_MINUTES="${BUILD_TIMEOUT_MINUTES:-120}"
KERNEL_GIT_MODE="${KERNEL_GIT_MODE:-shallow}"

SELECTED_SHA="$(git -C /armbian-build-src rev-parse HEAD)"
SELECTED_VERSION="$(git -C /armbian-build-src show "${SELECTED_SHA}:config/sources/families/include/rockchip64_common.inc" 2>/dev/null \
  | sed -n "/^[[:space:]]*${KERNEL_BRANCH})/,/^[[:space:]]*;;/p" \
  | grep "KERNEL_MAJOR_MINOR=" | head -1 | grep -oE "[0-9]+[.][0-9]+" | head -1 || true)"

echo "=== Step 2: Use selected Armbian ref HEAD ==="
echo "Armbian commit: ${SELECTED_SHA}"
if [ -n "${SELECTED_VERSION}" ]; then
  echo "Kernel line from ref: ${SELECTED_VERSION}"
fi

echo "=== Step 3: Copy userpatches from repo ==="
rm -rf /workspace/userpatches
cp -r /repo-src/userpatches /workspace/userpatches

echo "=== Step 4: Build kernel from selected ref ==="
echo "--- Attempt 1/1: ${KERNEL_BRANCH} @ ${SELECTED_SHA} (timeout ${BUILD_TIMEOUT_MINUTES}m) ---"
rm -rf /workspace/armbian-build
git clone --quiet --no-checkout /armbian-build-src /workspace/armbian-build
cp -r /workspace/userpatches /workspace/armbian-build/
cd /workspace/armbian-build
git checkout -f "${SELECTED_SHA}"
rm -rf output

if ! timeout --foreground "${BUILD_TIMEOUT_MINUTES}m" ./compile.sh rk1-workarounds kernel \
  BOARD=turing-rk1 \
  BRANCH="${KERNEL_BRANCH}" \
  KERNEL_GIT="${KERNEL_GIT_MODE}" \
  USE_TMPFS=no \
  KERNEL_CONFIGURE=no; then
  rc=$?
  if [ "${rc}" -eq 124 ]; then
    echo "ERROR: Build timed out after ${BUILD_TIMEOUT_MINUTES}m"
  fi
  echo "ERROR: Kernel build failed at ${SELECTED_SHA}"
  exit 1
fi

# Verify we built a stable (non-RC) kernel
RESOLVED_BRANCH=$(grep -Rhm1 -E "KERNELBRANCH='[^']+'" output/logs 2>/dev/null \
  | sed -E "s/.*KERNELBRANCH='([^']+)'.*/\1/" || true)
if [ -n "${RESOLVED_BRANCH}" ]; then
  echo "Resolved Armbian KERNELBRANCH: ${RESOLVED_BRANCH}"
fi
if printf "%s" "${RESOLVED_BRANCH}" | grep -q -- "-rc"; then
  echo "ERROR: Resolved KERNELBRANCH is release-candidate (${RESOLVED_BRANCH})"
  exit 1
fi

cd /workspace

echo ""
echo "=== BUILD SUCCESS: ${SELECTED_VERSION} @ ${SELECTED_SHA} ==="
echo "=== .deb packages produced: ==="
find /workspace/armbian-build/output -type f -name "*.deb" | sort | xargs ls -lh
INNEREOF

echo "==> Starting container build"
run_docker run --rm --privileged \
  -e COLUMNS=160 \
  -e KERNEL_BRANCH="${KERNEL_BRANCH}" \
  -e BUILD_TIMEOUT_MINUTES="${BUILD_TIMEOUT_MINUTES}" \
  -e KERNEL_GIT_MODE="${KERNEL_GIT_MODE}" \
  -e ARMBIAN_RUNNING_IN_CONTAINER=yes \
  -e PRE_PREPARED_HOST=yes \
  -e NO_HOST_RELEASE_CHECK=yes \
  -e LANG=C.UTF-8 \
  -v /dev:/dev \
  -v "${WORKDIR}":/workspace \
  -v "${ARMBIAN_SRC}":/armbian-build-src:ro \
  -v "${ROOT_DIR}":/repo-src:ro \
  -v "${INNER_SCRIPT}":/kernel-build-inner.sh:ro \
  -w /workspace \
  "${ARMBIAN_IMAGE}" \
  bash -l /kernel-build-inner.sh

rm -f "${INNER_SCRIPT}"

echo ""
echo "==> Done. Deb files on host:"
find "${WORKDIR}/armbian-build/output" -type f -name "*.deb" | sort
