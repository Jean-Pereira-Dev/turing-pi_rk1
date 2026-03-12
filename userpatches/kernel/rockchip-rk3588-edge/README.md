# Kernel patches — rockchip-rk3588 / edge branch

Place `.patch` files in this directory to apply them on top of Armbian's default
kernel patch set when building with `BOARD=turing-rk1 BRANCH=edge`.

The `edge` branch tracks the latest mainline kernel from kernel.org, making it the
preferred branch for picking up the newest upstream hardware support.

## Naming Convention

Patches are applied in lexicographic order. Use a numeric prefix to control the
order:

```
0001-description-of-fix.patch
0002-another-improvement.patch
```

## Examples of patches useful for the Turing Pi RK1 (BRANCH=edge)

* Early-adoption mainline kernel fixes for RK3588
* New hardware enablement that hasn't merged upstream yet
* Experimental NPU / media engine patches
* Power / thermal management improvements

## Reference

* Armbian userpatches docs: https://docs.armbian.com/Developer-Guide_User-Configurations/
* RK3588 upstream kernel patches: https://lore.kernel.org/linux-rockchip/
