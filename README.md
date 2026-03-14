# Turing Pi RK1 — Armbian Build System

Automated build system for [Armbian](https://github.com/armbian/build) images and
kernel packages targeting the **Turing Pi RK1** compute module (Rockchip RK3588S).

All jobs run on a **self-hosted Linux runner** inside a **custom Fedora 43 Docker
builder image**, keeping the runner host clean while still running Armbian in a
fully reproducible containerized environment.

The weekly kernel workflow checks kernel.org stable releases and builds Armbian
kernel packages on the `current` branch from the selected Armbian release ref
only when a newer stable kernel is available.

This repository's RK1 `current` profile now keeps broad upstream module
coverage by default and supports explicit force-enable lists for module symbols
that must match a known-good running RK1 kernel.

## What Gets Built

| Artifact | Trigger | Published to |
|----------|---------|--------------|
| Full OS image (`.img.xz`) | Monthly — day 1 at **15:00 Europe/Berlin** | GitHub Release (tag `image-YYYY-MM`) |
| Kernel packages (`.deb`) | Weekly check — **Tuesday at 13:00 Europe/Berlin**; builds only when kernel.org has a newer **stable** version | APT repository on GitHub Pages |

---

## APT Repository

Kernel packages are available as a Debian APT repository at:

```
https://Jean-Pereira-Dev.github.io/turing-pi_rk1
```

> **First-time setup:** Enable GitHub Pages on the `gh-pages` branch before the
> first kernel build runs (Settings → Pages → Branch: `gh-pages` / root).
> Updating the `gh-pages` branch alone is not enough; the APT URL will keep
> returning `404` until GitHub Pages is enabled for that branch.

> **Fork note:** Replace `Jean-Pereira-Dev` with your own GitHub username if you
> fork this repository.

### Add the repository

```bash
echo "deb [trusted=yes] https://Jean-Pereira-Dev.github.io/turing-pi_rk1 bookworm main" \
  | sudo tee /etc/apt/sources.list.d/turing-rk1-kernel.list
sudo apt update
```

### Optional: signed APT metadata (recommended)

When workflow secrets `APT_GPG_PRIVATE_KEY`, `APT_GPG_KEY_ID`, and optional
`APT_GPG_PASSPHRASE` are configured, kernel publishing also emits
`InRelease`/`Release.gpg`. In that case you can add this repository without
`trusted=yes` after importing your public key.

Built images already include this APT source at
`/etc/apt/sources.list.d/turing-rk1-kernel.list` via
`userpatches/customize-image.sh`.

### Install the kernel

```bash
sudo apt install linux-image-current-rockchip64 \
                 linux-dtb-current-rockchip64 \
                 linux-headers-current-rockchip64
sudo reboot
```

The repository always keeps the **two most recent kernel versions**; older versions
are pruned automatically after each successful build.

Published filenames in `pool/main/` include a kernel marker for readability,
using `+k<kernel-version>` in the version segment.

---

## Workflows

### [`build-image.yml`](.github/workflows/build-image.yml) — Monthly Image Build

Builds a complete bootable Armbian OS image for the Turing Pi RK1.

The workflow builds the Fedora builder image from [`docker/fedora/Dockerfile`](docker/fedora/Dockerfile)
and then runs it via an explicit `docker run --privileged` step. It clones this repository,
overlays `userpatches/`, builds the image with Armbian `compile.sh`, and uploads
the generated image files to a GitHub Release tagged `image-YYYY-MM`.

Scheduled runs are hard-gated to execute only at **day 1, 15:00 Europe/Berlin**.

**Manual trigger:** *Actions → Build Armbian Image (Monthly) → Run workflow*.
Optional overrides: kernel branch (`current`, `edge`, `vendor`) and OS release
(`noble`, `jammy`).

### [`build-kernel.yml`](.github/workflows/build-kernel.yml) — Weekly Kernel Check & Build

Checks for new upstream kernels once a week. It follows a **stable-kernel policy**:
the workflow selects kernel.org releases with `moniker=stable` and builds using
Armbian `BRANCH=current`.

Scheduled runs are hard-gated to execute only at **Tuesday, 13:00 Europe/Berlin**.
Manual `workflow_dispatch` runs are allowed at any time.

The pipeline has two sequential jobs:

| Job | Container | What it does |
|-----|-----------|-------------|
| `check-kernel-version` | runner host | Fetches latest stable version from [kernel.org](https://www.kernel.org/releases.json), compares it with `latest-kernel.txt` in the published APT repo |
| `build-and-publish-kernel` | Fedora builder image | Runs full flow in one Docker container: build `.deb`, tag filenames with kernel marker, update `pool/main/`, keep 2 latest versions, regenerate APT metadata, optionally sign metadata, push to `gh-pages` |

**Manual trigger:** *Actions → Build Kernel (Check Weekly for New Versions) → Run workflow*.
Set *Force build* to `true` to build unconditionally.

---

## Runner Requirements

| Requirement | Notes |
|-------------|-------|
| Linux (x86-64) | Any recent distro with Docker support |
| Docker | The runner user must be in the `docker` group |
| `curl`, `python3` | Used by `check-kernel-version` on the runner host |
| ~30 GB free disk space | For Armbian build output |

Both workflows build the Fedora builder image automatically on first use.
Kernel publishing to `gh-pages` is done inside that same container (no separate
host publish job).

---

## Customising the Kernel

Drop `.patch` files into the appropriate `userpatches/kernel/` subdirectory.
Patches are applied on top of Armbian's built-in set in lexicographic order.

The default `userpatches/config-rk1-workarounds.conf.sh` profile keeps broad
module coverage and supports additional per-symbol forcing with
`userpatches/rk1-current-force-modules.txt`.

Aggressive module trimming remains available as an opt-in mode only:

```bash
RK1_ENABLE_MODULE_TRIM=yes
```

When trim mode is enabled, it applies an opinionated profile for
**Turing Pi 2 + RK1 general use**:

- Wi-Fi enabled
- Bluetooth enabled
- Sound enabled
- Touchscreen, joystick, IR/media-remote, and many vendor HID drivers disabled
- USB serial and USB network dongle long-tail drivers disabled
- CAN, NFC, 802.15.4, PMBus, IIO sensor, USBIP, and several other niche stacks disabled
- Many MIPI/LVDS panel drivers disabled

If you need one of the trimmed peripheral families, remove or override those
config changes before rebuilding.

For the weekly kernel workflow in this repository, patches under
`userpatches/kernel/rockchip-rk3588-current/` are applied by default because the
kernel workflow uses `BRANCH=current`.

```
userpatches/
└── kernel/
    ├── rockchip-rk3588-current/   ← patches for BRANCH=current
    │   └── README.md
    └── rockchip-rk3588-edge/      ← patches for BRANCH=edge
        └── README.md
```

---

## Building Locally

Prerequisites: Docker installed, `git`, ~30 GB free disk space.

```bash
# Clone this repo
git clone https://github.com/Jean-Pereira-Dev/turing-pi_rk1.git
cd turing-pi_rk1

# Build the Fedora builder image
./scripts/build-fedora-builder-image.sh

# Clone Armbian build system
git clone --depth=1 https://github.com/armbian/build.git armbian-build

# Copy userpatches
cp -r userpatches armbian-build/

# Build full image (current branch, Ubuntu Noble)
docker run --rm --privileged \
  -e ARMBIAN_RUNNING_IN_CONTAINER=yes \
  -e PRE_PREPARED_HOST=yes \
  -e NO_HOST_RELEASE_CHECK=yes \
  -v "$(pwd)/armbian-build:/armbian" \
  turing-rk1-fedora-builder:fedora43 \
  bash -c "cd /armbian && ./compile.sh BOARD=turing-rk1 BRANCH=current RELEASE=noble \
    BUILD_MINIMAL=no BUILD_DESKTOP=no KERNEL_CONFIGURE=no COMPRESS_OUTPUTIMAGE=sha,xz"

# Build kernel packages only with the local helper
scripts/build-kernel-local.sh
```

Output images land in `armbian-build/output/images/`.  
Kernel `.deb` packages land in `armbian-build/output/debs/`.

---

## Notes

- APT metadata signing support is implemented and activates automatically when
  signing secrets are configured.

---

## License

[BSD 3-Clause](LICENSE)
