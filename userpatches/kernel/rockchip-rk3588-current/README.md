# Kernel patches — rockchip-rk3588 / current branch

Place `.patch` files in this directory to apply them on top of Armbian's default
kernel patch set when building with `BOARD=turing-rk1 BRANCH=current`.

## Naming Convention

Patches are applied in lexicographic order. Use a numeric prefix to control the
order:

```
0001-description-of-fix.patch
0002-another-improvement.patch
```

## Examples of patches useful for the Turing Pi RK1 (BRANCH=current)

* Board-specific Device Tree tweaks
* PCIe/NVMe stability fixes
* USB 3.0 enumeration improvements
* Power management tuning
* BMC/management controller integration

## Reference

* Armbian userpatches docs: https://docs.armbian.com/Developer-Guide_User-Configurations/
* RK3588 upstream kernel patches: https://lore.kernel.org/linux-rockchip/
