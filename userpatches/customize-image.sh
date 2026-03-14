#!/usr/bin/env bash
set -euo pipefail

# Add the project kernel APT repo into built images so updates are available
# immediately after first boot.
REPO_URL="https://Jean-Pereira-Dev.github.io/turing-pi_rk1"
LIST_REL_PATH="/etc/apt/sources.list.d/turing-rk1-kernel.list"

# Armbian can expose the target rootfs through $SDCARD during customization.
# Fall back to / when running directly inside a target root context.
TARGET_ROOT="${SDCARD:-/}"
if [ ! -d "${TARGET_ROOT}/etc/apt/sources.list.d" ]; then
  mkdir -p "${TARGET_ROOT}/etc/apt/sources.list.d"
fi

cat > "${TARGET_ROOT}${LIST_REL_PATH}" <<EOF
# Turing Pi RK1 kernel repository
# Added automatically by userpatches/customize-image.sh
deb [trusted=yes] ${REPO_URL} bookworm main
EOF

echo "Added kernel repository: ${TARGET_ROOT}${LIST_REL_PATH}"
