# Turing Pi RK1 — Armbian Build System

Automated build system for [Armbian](https://github.com/armbian/build) images and
kernel packages targeting the **Turing Pi RK1** compute module (Rockchip RK3588S).

All builds run on a **self-hosted Linux runner** and always execute **inside Docker**
(via Armbian's built-in Docker mode), so the host stays clean.

## What Gets Built

| Artifact | Trigger | Distribution |
|----------|---------|--------------|
| Full OS image (`.img.xz`) | Monthly — 1st of each month at 02:00 UTC | GitHub Release (tagged `image-YYYY-MM`) |
| Kernel packages (`.deb`) | Daily check — builds when a new stable kernel is found on kernel.org | APT repository on GitHub Pages |

---

## APT Repository

Kernel packages are published as an APT repository at:

```
https://Jean-Pereira-Dev.github.io/turing-pi_rk1
```

> **Note:** Enable GitHub Pages on the `gh-pages` branch of this repository before
> the first kernel build runs (Settings → Pages → Branch: `gh-pages` / `root`).

> **Fork note:** If you fork this repository, replace `Jean-Pereira-Dev` with your
> GitHub username/organisation in the `deb` line below and in your sources list.

### Add to your Turing Pi RK1

```bash
echo "deb [trusted=yes] https://Jean-Pereira-Dev.github.io/turing-pi_rk1 bookworm main" \
  | sudo tee /etc/apt/sources.list.d/turing-rk1-kernel.list
sudo apt update
```

### Install the latest kernel

```bash
sudo apt install linux-image-edge-rockchip64 \
                 linux-dtb-edge-rockchip64 \
                 linux-headers-edge-rockchip64
sudo reboot
```

The repository always keeps the **two most recent kernel versions**. Older versions
are automatically pruned after each successful build.

---

## Workflows

### [`build-image.yml`](.github/workflows/build-image.yml) — Monthly Image Build

Clones the upstream Armbian build system fresh on every run, copies the local
`userpatches/` directory into it, and compiles a complete bootable OS image inside
Docker (via `compile.sh docker`).

Published as a GitHub Release tagged `image-YYYY-MM`.

**Manual trigger:** Go to *Actions → Build Armbian Image (Monthly) → Run workflow*
and optionally override the kernel branch (`current`, `edge`, `vendor`) and OS
release (`noble`, `jammy`).

### [`build-kernel.yml`](.github/workflows/build-kernel.yml) — Daily Kernel Check & Build

Runs daily. The pipeline has three sequential jobs:

| Job | What it does |
|-----|-------------|
| `check-kernel-version` | Fetches the latest stable version from [kernel.org](https://www.kernel.org/releases.json), compares it with `latest-kernel.txt` in the APT repo, decides whether to build |
| `build-kernel` | Clones Armbian, copies userpatches, builds kernel `.deb` packages inside Docker |
| `publish-apt-repo` | Downloads the new packages, adds them to `pool/main/`, prunes kernels older than the 2 most recent, regenerates `Packages`/`Release` metadata, pushes to the `gh-pages` branch |

**Manual trigger:** Go to *Actions → Build Kernel (Check Daily for New Versions) →
Run workflow*. Set *Force build* to `true` to build unconditionally.

---

## Runner Requirements

The self-hosted runner must have:

| Requirement | Notes |
|-------------|-------|
| Linux (x86-64) | Ubuntu 22.04+ recommended |
| Docker | Runner user must be in the `docker` group |
| `git`, `curl`, `python3` | For the check-kernel-version job |
| `dpkg-dev` (or `sudo apt-get install dpkg-dev`) | For generating APT metadata; auto-installed if missing |
| ~30 GB free disk space | For Armbian build artifacts |

Armbian's `compile.sh docker` automatically pulls/updates its own build container,
so no Armbian-specific dependencies are needed on the host.

---

## Customising the Kernel

Custom patches and kernel config overrides live under `userpatches/`:

```
userpatches/
└── kernel/
    ├── rockchip-rk3588-current/   ← patches for BRANCH=current
    │   └── README.md
    └── rockchip-rk3588-edge/      ← patches for BRANCH=edge
        └── README.md
```

Drop `.patch` files into the appropriate directory. They are applied on top of
Armbian's built-in patch set in lexicographic order. See the README inside each
directory for guidance.

---

## Building Locally

Prerequisites: Ubuntu 22.04+ host, Docker, `git`, ~30 GB free disk space.

```bash
# Clone this repo
git clone https://github.com/Jean-Pereira-Dev/turing-pi_rk1.git
cd turing-pi_rk1

# Clone Armbian build system
git clone --depth=1 https://github.com/armbian/build.git armbian-build

# Copy userpatches
cp -r userpatches armbian-build/

# Build full image (current branch, Ubuntu Noble) — inside Docker
cd armbian-build
./compile.sh docker BOARD=turing-rk1 BRANCH=current RELEASE=noble \
  BUILD_MINIMAL=no BUILD_DESKTOP=no KERNEL_CONFIGURE=no

# Build kernel packages only (edge branch) — inside Docker
./compile.sh docker kernel BOARD=turing-rk1 BRANCH=edge KERNEL_CONFIGURE=no
```

Output images land in `armbian-build/output/images/`.  
Kernel `.deb` packages land in `armbian-build/output/debs/`.

---

## License

[BSD 3-Clause](LICENSE)