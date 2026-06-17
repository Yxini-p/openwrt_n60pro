# N60 Pro OpenWrt Firmware Build Guide

## Source Repository
- **Use**: `https://github.com/padavanonly/immortalwrt-mt798x-24.10` (branch: `openwrt-24.10-6.6`)
- **DO NOT use**: `padavanonly/immortalwrt-mt798x-6.6` — this is an older repo without mt_wifi Makefile fixes

The correct repo already has these critical fixes:
- `WIFI_DRV_PATH="$(PKG_BUILD_DIR)"` in mt_wifi Build/Compile
- `EXTRA_CFLAGS="-DLINUX"` in mt_wifi Build/Compile
- `FIX_MT_WIFI_MAKEFILE` hook that patches the internal `mt_wifi_ap/Makefile` (`:=` → `?=`, `=` → `?=`)

## Build Method
1. Start from `defconfig/mt7975-ipailna-high-power.config` as the base (official high-power config for MT7975 iPAiLNA)
2. Change device to N60 Pro, and ONLY the device — do NOT manually add/remove individual MTK config options
3. Remove bloat packages (ssr-plus, passwall, python, node, etc.)
4. Fix dnsmasq: replace `dnsmasq-full` with basic `dnsmasq` (dnsmasq-full fails to link against libnettle)
5. Add DDNS: `luci-app-ddns`, `ddns-scripts`, `ddns-scripts-services`, `curl`, `libcurl`, `bind-host`, `bind-libs`, `bind-dig`
6. Change default IP to `192.168.2.1`
7. Run `make defconfig`, then strip any remaining dnsmasq-full entries, then `make -j$(nproc)`

## Critical Config Rules
- `CONFIG_MTK_MT_WIFI=m` (not `=y`) — must be module for external kernel module build
- `CONFIG_MTK_MT_AP_SUPPORT=m` — same reason
- `CONFIG_MTK_WIFI_MODE_AP=m` — same reason
- `CONFIG_MTK_FIRST_IF_MT7986=y` — first radio interface
- `CONFIG_MTK_FIRST_IF_IPAILNA=y` — N60 Pro uses iPAiLNA FEM
- `CONFIG_MTK_WIFI_ADIE_TYPE="mt7976"` — antenna type
- `CONFIG_WARP_VERSION=2`, `CONFIG_WARP_CHIPSET="mt7986"` — correct for MT7986
- `CONFIG_TARGET_DEVICE_PACKAGES_...="-dnsmasq-full"` to exclude dnsmasq-full
- Device packages use `-prefix` to remove defaults

## Known Issues & Fixes
1. **`make defconfig` clears device selection**: Always add device AFTER `make defconfig`
2. **dnsmasq-full fails**: libnettle linking error in dnsmasq-full. Use basic `dnsmasq` instead
3. **curl/bind fail**: Need `libcurl` + `libnghttp2` + `libopenssl` + `libz` explicitly selected; also `bind-libs`
4. **conninfra #ifdef mismatch**: Source uses `CONNINFRA_APSOC_MT7986` but Makefile passes `CONFIG_MTK_CONNINFRA_APSOC_MT7986`. Fixed in correct repo
5. **MTK kernel symbols**: `kmod-mediatek_hnat` required for `HIT_BIND_FORCE_TO_CPU` etc.
6. **Out-of-sync warning is non-fatal**: `make` proceeds despite "out of sync" warning

## Adding Custom Packages
- Clone to `package/custom/<pkg>/` — the build system auto-discovers packages there
- Ensure dependencies are correct (e.g., luci-app-quickfile does NOT need luci-nginx — it runs standalone)
- No `make menuconfig` needed — just add `CONFIG_PACKAGE_<pkg>=y` to .config
- If you build a package from source that needs dependencies, remove those deps from .config too (e.g., nginx, luci-nginx) — they will block `package/install`

## Docker Build
- Image: `openwrt-builder` (based on ubuntu:22.04)
- Mount source at `/home/builder/openwrt`
- Use `--network host` for proxy access
- **Must set `-e http_proxy=http://192.168.2.1:7890` and `-e https_proxy=http://192.168.2.1:7890`** at `docker run`, otherwise downloads from SourceForge/GitHub stall
- CCache at `/home/builder/.ccache`
- Run `make download -j4` first if downloads are slow

## Slimming Reference Config
When stripping bloat from `mt7975-ipailna-high-power.config`:
- Remove `ssr-plus`, `passwall`, `vssr`, `rclone` families
- Remove `python*`, `node*` packages (heavy, only needed by above)
- Remove `nginx`, `luci-nginx`, `uwsgi` if not needed (quickfile runs standalone)
- Keep `luci-app-turboacc-mtk` and MTK tools (hardware acceleration)
- After removing, check `.config` has no remaining `=y` for these — also strip `# CONFIG...is not set` lines

## Deployment
- Uboot web at `192.168.1.1` (hold reset + power on)
- Flash `squashfs-sysupgrade.bin` via uboot web UI
- Router SSH: root@192.168.2.1, port 12345 or 22

## Firmware Verification Checklist
Before flashing, verify:
- `BOARD=netcore_n60-pro` in image strings
- `supported_devices` includes `netcore,n60-pro`
- Size fits within 128MB flash (26MB is fine)
- Key packages present: `kmod-mt_wifi`, `kmod-warp`, `kmod-mediatek_hnat`, `dnsmasq`, `ddns-scripts`
- Bloat absent: no ssr-plus, passwall, python, node, nginx
