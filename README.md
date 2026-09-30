# Experimental OpenWrt for TP-Link Archer AX53 (EU) v1

Experimental device port and research notes, tested on one physical AX53 EU v1 on 2026-09-30. **Not official OpenWrt support; not a ready-to-flash release. AX53 v2 is outside this project.**

## Status

| Component | Observed result |
| --- | --- |
| Linux | OpenWrt aarch64, Linux 6.18.52 boots |
| NAND | SquashFS root + persistent UBIFS overlay boot from the rootfs slot |
| Ethernet | RTL8367S detected over MDIO1 address 0x1d; CPU link 2500base-x; management through physical WAN confirmed |
| LAN port numbering | Not fully checked against enclosure labels |
| SSH / LuCI | Accessible; LuCI login confirmed |
| 2.4 GHz | IPQ5018 ath11k; TEST AP independently observed in HT20 |
| 5 GHz | QCN6102-family radio; TEST AP independently observed in VHT80; phone association reported |
| Wi-Fi 6 | Unresolved regional behavior: RU yields firmware-derived NO-HE; later US/HE80 configuration starts a 5 GHz AP, but negotiated HE/client performance is not verified |
| Warm reboot | Intermittent failure to return after enabling Wi-Fi; cold power cycle restores access. Cause unproven |
| Routing / NAT / WAN separation | Not validated; tested as a bridged access point |
| Internet through Wi-Fi client | Not yet independently validated end to end |
| sysupgrade / factory installation | Not validated; device-specific sysupgrade deliberately refuses |

## Source basis

OpenWrt commit `3ab520425b127d66617bfeb1e2805b4f20109f95`:
https://github.com/openwrt/openwrt/tree/3ab520425b127d66617bfeb1e2805b4f20109f95

Target: `qualcommax/ipq50xx`. The pinned tree already includes Realtek RTL8367S, SGMII/HSGMII and Qualcomm IPQ5018 DWMAC/UNIPHY support. Do not replace these with a generic older kernel driver.

The main patch adds the AX53 DTS, image profile, bridged AP port setup and a guard rejecting unvalidated sysupgrade. The optional WMI logging patch only logs regulatory event identities; it does not remove restrictions.

**The image profile alone is incomplete:** the tested device also has `ath11k-firmware-ipq5018-qcn6122`, native per-device calibration and LuCI installed separately. No automatic AX53 ART extraction hook is included yet. See [build notes](docs/BUILD.md).

## Hardware and Wi-Fi

IPQ5018 provides 2.4 GHz. Documentation identifies the external radio as QCN6102. OpenWrt intentionally shares the `qcom,qcn6122-wifi` binding and `ath11k-firmware-ipq5018-qcn6122` family with QCN6102 boards; the name is not proof of QCN6122 silicon.

AX53 uses Q6 root + internal PD1 and external PD2 (`wifi@b00a040`). The second external node `wifi@b00b040` stays disabled. Memory mode is 2. Q6 boot arguments are copied from the inspected AX53 stock FIT, not guessed from AX55.

Native calibration and boot findings: [hardware notes](docs/HARDWARE.md). Open issues: [known issues](docs/KNOWN-ISSUES.md).

## Installation status

No generic installation command is provided. The successful device used full local MTD backups, a verified inactive-slot UBI image and device-specific U-Boot environment work. Button-triggered TFTP recovery is not equivalent to RAM boot and may write flash. The tested image is not a TP-Link-signed factory firmware.

Do not write ART, bootloader or another device's calibration. Preserving a stock slot does not prove an automatic recovery path. Raw backups, personal configs, SSH keys, credentials and packet captures are excluded from this repository.

## References / prior work

- https://openwrt.org/inbox/toh/tp-link/archer_ax53_eu_1.0
- https://github.com/defencore/openwrt_tp-link_archer_ax53_eu_1.0
- https://github.com/kuncy7/openwrt-ax55-v1
- https://samuzora.com/posts/ax53/archer-ax53
- https://forum.openwrt.org/t/add-support-for-tp-link-ax53/190809

OpenWrt and Linux work retain their respective licenses and authorship. See COPYING and SPDX identifiers in the patch.
