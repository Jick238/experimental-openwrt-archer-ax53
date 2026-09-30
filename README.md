# Experimental OpenWrt for TP-Link Archer AX53 (EU) v1

Experimental device port and research notes, tested on one physical AX53 EU v1. Status reviewed on **2026-10-01**. **Not official OpenWrt support; not a ready-to-flash release. AX53 v2 is outside this project.**

## Status

| Component | Observed result |
| --- | --- |
| Linux | OpenWrt aarch64, Linux 6.18.52 boots |
| NAND | SquashFS root + persistent UBIFS overlay boot from the rootfs slot |
| Ethernet | RTL8367S detected over MDIO1 address 0x1d; CPU link 2500base-x; management through physical WAN confirmed |
| LAN port numbering | Not fully checked against enclosure labels |
| SSH / LuCI | Accessible; LuCI login confirmed |
| 2.4 GHz | IPQ5018 ath11k; AP running in HT20 with client association and traffic observed |
| 5 GHz | QCN6102-family radio; AP running in VHT80 with client association and traffic observed |
| Wi-Fi 6 | An earlier client snapshot reported HE-MCS/HE-NSS, but stable HE operation is not validated. Current baseline is HT20/VHT80; regional firmware restrictions remain under investigation |
| Warm reboot | Earlier intermittent failures; one ordinary warm reboot returned after the latest kernel/ath11k update. Cause remains unproven; Realtek boot patch is not active in the old ROM |
| Routing / NAT / WAN separation | Not validated; tested as a bridged access point |
| Internet through Wi-Fi client | End-to-end client connectivity and throughput validation remain in progress |
| Memory | 256 MiB physical RAM; Linux MemTotal 178.93 MiB. Experimental ath11k buffer reductions installed; pressure and throughput still monitored |
| Monitoring | Passive memory, queue/error and packet-loss telemetry; rotating remote logs on an Armbian disk, with independent router reachability probes |
| sysupgrade / factory installation | Not validated; device-specific sysupgrade deliberately refuses |

Latest update: experimental RX, TX and monitor pool reductions are installed. One ordinary warm reboot returned, both APs remained available during follow-up, and sampled OOM/allocstall and RXDMA/TCL overflow counters were zero. These observations do not establish long-term stability. See [worklog](docs/WORKLOG.md) and [monitoring](monitoring/README.md). Client-side connectivity and throughput tests remain pending.

## Source basis

OpenWrt commit `3ab520425b127d66617bfeb1e2805b4f20109f95`:
https://github.com/openwrt/openwrt/tree/3ab520425b127d66617bfeb1e2805b4f20109f95

Target: `qualcommax/ipq50xx`. The pinned tree already includes Realtek RTL8367S, SGMII/HSGMII and Qualcomm IPQ5018 DWMAC/UNIPHY support. Do not replace these with a generic older kernel driver.

The main patch adds the AX53 DTS, image profile, bridged AP port setup and a guard rejecting unvalidated sysupgrade. Additional patches are:

- `952`: numeric WMI regulatory-event logging; it does not remove restrictions.
- `953`: experimental RX and monitor buffer reductions.
- `954`: experimental TX completion and monitor pool reductions, applied after 953.
- `797`: the standalone Realtek SerDes/conduit startup-order change from [OpenWrt PR25153](https://github.com/openwrt/openwrt/pull/25153).

The buffer limits are build-wide experimental changes. They can reduce burst capacity or throughput; zero observed overflow counters do not prove there is no client-side packet loss.

**The image profile alone is incomplete:** the tested device also has `ath11k-firmware-ipq5018-qcn6122`, native per-device calibration and LuCI installed separately. No automatic AX53 ART extraction hook is included yet. See [build notes](docs/BUILD.md).

## Hardware and Wi-Fi

IPQ5018 provides 2.4 GHz. Documentation identifies the external radio as QCN6102. OpenWrt intentionally shares the `qcom,qcn6122-wifi` binding and `ath11k-firmware-ipq5018-qcn6122` family with QCN6102 boards; the name is not proof of QCN6122 silicon.

AX53 uses Q6 root + internal PD1 and external PD2 (`wifi@b00a040`). The second external node `wifi@b00b040` stays disabled. Memory mode is 2. Q6 boot arguments are copied from the inspected AX53 stock FIT, not guessed from AX55.

### Memory and current boot limitation

The boot log reserves **48 MiB for WCSS/Q6**, plus 10 MiB for TrustZone,
bootloader and related service regions. Kernel memory and other reservations
bring Linux MemTotal to 178.93 MiB. Driver buffers additionally consume memory
from that pool. Reducing those buffers increases free memory, not MemTotal.

The latest device update replaced the NAND UBI kernel volume and matching
modules while retaining the old read-only rootfs and persistent configuration.
**The Realtek boot patch is built but not active on this device:** preinit
loads the old module from ROM before overlay. Installing the patched file in
overlay did not replace that already-loaded module. A validated read-only
rootfs update is still required; the successful reboot cannot be attributed
to PR25153.

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
