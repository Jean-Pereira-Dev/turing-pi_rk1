# Turing Pi RK1 — Armbian Build System

Automated build system for [Armbian](https://github.com/armbian/build) images and
kernel packages targeting the **Turing Pi RK1** compute module (Rockchip RK3588S).

All jobs run on a **self-hosted Linux runner** inside the **official Armbian Docker
container**, keeping the runner host clean and the build environment fully reproducible.

## What Gets Built

| Artifact | Trigger | Published to |
|----------|---------|--------------|
| Full OS image (`.img.xz`) | Monthly — 1st of each month at 02:00 UTC | GitHub Release (tag `image-YYYY-MM`) |
| Kernel packages (`.deb`) | Daily check — builds when kernel.org has a newer stable version | APT repository on GitHub Pages |

---

## APT Repository

Kernel packages are available as a Debian APT repository at:

```
https://Jean-Pereira-Dev.github.io/turing-pi_rk1
```

> **First-time setup:** Enable GitHub Pages on the `gh-pages` branch before the
> first kernel build runs (Settings → Pages → Branch: `gh-pages` / root).

> **Fork note:** Replace `Jean-Pereira-Dev` with your own GitHub username if you
> fork this repository.

### Add the repository

```bash
echo "deb [trusted=yes] https://Jean-Pereira-Dev.github.io/turing-pi_rk1 bookworm main" \
  | sudo tee /etc/apt/sources.list.d/turing-rk1-kernel.list
sudo apt update
```

### Install the kernel

```bash
sudo apt install linux-image-edge-rockchip64 \
                 linux-dtb-edge-rockchip64 \
                 linux-headers-edge-rockchip64
sudo reboot
```

The repository always keeps the **two most recent kernel versions**; older versions
are pruned automatically after each successful build.

---

## Workflows

### [`build-image.yml`](.github/workflows/build-image.yml) — Monthly Image Build

Builds a complete bootable Armbian OS image for the Turing Pi RK1.

The job runs inside `ghcr.io/armbian/docker-armbian-build:armbian-ubuntu-jammy-latest`
(declared via the workflow `container:` key). Armbian's `compile.sh` detects the
container environment and builds natively without spawning a nested container.
The finished image is published as a GitHub Release tagged `image-YYYY-MM`.

**Manual trigger:** *Actions → Build Armbian Image (Monthly) → Run workflow*.
Optional overrides: kernel branch (`current`, `edge`, `vendor`) and OS release
(`noble`, `jammy`).

### [`build-kernel.yml`](.github/workflows/build-kernel.yml) — Daily Kernel Check & Build

Checks for new upstream kernels every day. The pipeline has three sequential jobs:

| Job | Container | What it does |
|-----|-----------|-------------|
| `check-kernel-version` | runner host | Fetches the latest stable version from [kernel.org](https://www.kernel.org/releases.json), compares it with `latest-kernel.txt` published in the APT repo |
| `build-kernel` | Armbian build image | Clones Armbian, overlays `userpatches/`, builds kernel `.deb` packages |
| `publish-apt-repo` | `ubuntu:22.04` | Downloads new packages, updates `pool/main/`, prunes to 2 latest versions, regenerates `Packages`/`Release` metadata, pushes to `gh-pages` |

**Manual trigger:** *Actions → Build Kernel (Check Daily for New Versions) → Run workflow*.
Set *Force build* to `true` to build unconditionally.

---

## Runner Requirements

| Requirement | Notes |
|-------------|-------|
| Linux (x86-64) | Ubuntu 22.04+ recommended |
| Docker | The runner user must be in the `docker` group |
| `curl`, `python3` | Used by `check-kernel-version` on the runner host |
| ~30 GB free disk space | For Armbian build output |

`build-kernel` and `build-image` jobs pull the Armbian build container automatically
on first use. `publish-apt-repo` uses a standard `ubuntu:22.04` container and
installs `dpkg-dev` and `git` via `apt-get` at the start of the job.

---

## Customising the Kernel

Drop `.patch` files into the appropriate `userpatches/kernel/` subdirectory.
Patches are applied on top of Armbian's built-in set in lexicographic order.

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

# Clone Armbian build system
git clone --depth=1 https://github.com/armbian/build.git armbian-build

# Copy userpatches
cp -r userpatches armbian-build/

# Build full image (current branch, Ubuntu Noble)
docker run --rm --privileged \
  -v "$(pwd)/armbian-build:/armbian" \
  ghcr.io/armbian/docker-armbian-build:armbian-ubuntu-jammy-latest \
  bash -c "cd /armbian && ./compile.sh BOARD=turing-rk1 BRANCH=current RELEASE=noble \
    BUILD_MINIMAL=no BUILD_DESKTOP=no KERNEL_CONFIGURE=no COMPRESS_OUTPUTIMAGE=sha,xz"

# Build kernel packages only (edge branch)
docker run --rm --privileged \
  -v "$(pwd)/armbian-build:/armbian" \
  ghcr.io/armbian/docker-armbian-build:armbian-ubuntu-jammy-latest \
  bash -c "cd /armbian && ./compile.sh kernel BOARD=turing-rk1 BRANCH=edge KERNEL_CONFIGURE=no"
```

Output images land in `armbian-build/output/images/`.  
Kernel `.deb` packages land in `armbian-build/output/debs/`.

---

## License

[BSD 3-Clause](LICENSE)
