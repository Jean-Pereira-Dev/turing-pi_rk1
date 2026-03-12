# Turing Pi RK1 — Armbian Build System

Automated build system for [Armbian](https://github.com/armbian/build) images and
kernel packages targeting the **Turing Pi RK1** compute module (Rockchip RK3588S).

## What Gets Built

| Artifact | Trigger | Armbian Branch |
|----------|---------|----------------|
| Full OS image (`.img.xz`) | Monthly — 1st of each month at 02:00 UTC | `current` (LTS) |
| Kernel packages (`.deb`) | Daily check — builds when kernel.org releases a new stable version | `edge` (latest mainline) |

Releases are published to the [Releases](../../releases) page of this repository.

---

## Workflows

### [`build-image.yml`](.github/workflows/build-image.yml) — Monthly Image Build

Clones the upstream Armbian build system fresh on every run, copies the local
`userpatches/` directory into it, and compiles a complete bootable OS image.

**Manual trigger:** Go to *Actions → Build Armbian Image (Monthly) → Run workflow*
and optionally override the kernel branch (`current`, `edge`, `vendor`) and OS
release (`noble`, `jammy`).

### [`build-kernel.yml`](.github/workflows/build-kernel.yml) — Kernel Version Check & Build

Runs daily. Fetches the latest stable kernel version from
[kernel.org](https://www.kernel.org/releases.json), compares it with the version
tag of the most recent kernel release in this repository, and starts a build only
when a newer version is found.

**Manual trigger:** Go to *Actions → Build Kernel (Check Daily for New Versions) →
Run workflow*. Set *Force build* to `true` to build unconditionally.

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

Prerequisites: Ubuntu 22.04+ host, `git`, `sudo`, ~20 GB free disk space.

```bash
# Clone this repo
git clone https://github.com/Jean-Pereira-Dev/turing-pi_rk1.git
cd turing-pi_rk1

# Clone Armbian build system
git clone --depth=1 https://github.com/armbian/build.git armbian-build

# Copy userpatches
cp -r userpatches armbian-build/

# Build full image (current branch, Ubuntu Noble)
cd armbian-build
sudo ./compile.sh BOARD=turing-rk1 BRANCH=current RELEASE=noble \
  BUILD_MINIMAL=no BUILD_DESKTOP=no KERNEL_CONFIGURE=no

# Build kernel packages only (edge branch)
sudo ./compile.sh kernel BOARD=turing-rk1 BRANCH=edge KERNEL_CONFIGURE=no
```

Output images land in `armbian-build/output/images/`.  
Kernel `.deb` packages land in `armbian-build/output/debs/`.

---

## License

[BSD 3-Clause](LICENSE)