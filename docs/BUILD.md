# Build scope and reproduction

Clone OpenWrt and check out `3ab520425b127d66617bfeb1e2805b4f20109f95`. Apply `patches/0001-archer-ax53-v1-experimental-port.patch` from the OpenWrt root using `git apply`.

Select qualcommax / ipq50xx / TP-Link Archer AX53 v1. The device profile uses FIT configuration `config@mp02.1`, LZMA, 128 KiB eraseblocks, 2048-byte pages, 128 MiB NAND and a 43008 KiB firmware slot.

The successful test additionally selected/installed `ath11k-firmware-ipq5018-qcn6122`, firmware dependencies and LuCI. For diagnostic builds, copy the optional logging patch into `package/kernel/mac80211/patches/ath11k/`.

Native calibration must be supplied from the same physical device; automatic extraction is not implemented in this snapshot. See HARDWARE.md. Do not reuse someone else's ART.

This repository is a source snapshot, not a complete reproducible release recipe. The exact private overlay used for hardware testing contains device keys/configuration and is intentionally excluded. A clean image from this patch has not been hardware-tested. Default AP networking puts WAN and LAN ports in one LAN bridge; it is not a routed WAN configuration.

No binaries are published because tested artifacts contain personal configuration. There is no validated sysupgrade or vendor-web-interface install path.

## Additional experimental patches

Copy `953-ath11k-reduce-rx-rings-experimental-256m.patch` and
`954-ath11k-reduce-tx-monitor-pools-experimental-256m.patch` to
`package/kernel/mac80211/patches/ath11k/`. Both are build-wide limits;
954 requires 953 and reduces TX completion 32768→8192, monitor destination
2048→512 and monitor link descriptors 4096→1024. The additional nominal
saving is about 3–4 MiB from allocation arithmetic, not a controlled measurement.
Smaller rings can cause burst loss, completion starvation or throughput loss.

Copy `797-net-dsa-realtek-rtl8365mb-bring-the-SerDes-up-once-the-conduit-is-up.patch`
to `target/linux/generic/pending-6.18/`. It preserves the original author and
implements the standalone change from OpenWrt PR25153; PR19644's broader
series is not included. This addresses Linux SerDes/conduit startup order,
not U-Boot Ethernet or Q6 reset.

**Early module loading matters:** RTL8365MB is loaded in preinit through
`/etc/modules-boot.d/42-dsa-rtl8365mb`. Updating only the module in overlay
can leave the old ROM module running. The latest test confirmed the new
callback was absent from live kallsyms even though the patched file existed
in overlay. A rebuilt read-only rootfs is required to activate this patch
on that boot path. No general rootfs replacement procedure is validated here.
