# Build scope and reproduction

Clone OpenWrt and check out `3ab520425b127d66617bfeb1e2805b4f20109f95`. Apply `patches/0001-archer-ax53-v1-experimental-port.patch` from the OpenWrt root using `git apply`.

Select qualcommax / ipq50xx / TP-Link Archer AX53 v1. The device profile uses FIT configuration `config@mp02.1`, LZMA, 128 KiB eraseblocks, 2048-byte pages, 128 MiB NAND and a 43008 KiB firmware slot.

The successful test additionally selected/installed `ath11k-firmware-ipq5018-qcn6122`, firmware dependencies and LuCI. For diagnostic builds, copy the optional logging patch into `package/kernel/mac80211/patches/ath11k/`.

Native calibration must be supplied from the same physical device; automatic extraction is not implemented in this snapshot. See HARDWARE.md. Do not reuse someone else's ART.

This repository is a source snapshot, not a complete reproducible release recipe. The exact private overlay used for hardware testing contains device keys/configuration and is intentionally excluded. A clean image from this patch has not been hardware-tested. Default AP networking puts WAN and LAN ports in one LAN bridge; it is not a routed WAN configuration.

No binaries are published because tested artifacts contain personal configuration. There is no validated sysupgrade or vendor-web-interface install path.
