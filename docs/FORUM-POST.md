# Experimental OpenWrt on TP-Link Archer AX53 EU v1: NAND boot, RTL8367S and both ath11k radios

I have an experimental port running on one physical Archer AX53 EU v1 (IPQ5018 + documented QCN6102 external radio).

Source and findings: https://github.com/Jick238/experimental-openwrt-archer-ax53
Base OpenWrt commit: 3ab520425b127d66617bfeb1e2805b4f20109f95, Linux 6.18.52.

Confirmed: NAND boot with SquashFS + persistent UBIFS overlay; SSH and LuCI; RTL8367S on MDIO1 0x1d with a 2500base-x CPU link; both ath11k radios probing; 2.4 GHz HT20 and 5 GHz VHT80 APs independently visible; phone association reported.

Native vendor ART archive matches raw 0:art. Calibration windows are 0x1000/0x20000 for IPQ5018 and 0x26800/0x20000 for the external radio. The port enables Q6 root, PD1 and PD2 (wifi@b00a040), memory mode 2. QCN6102 intentionally uses the shared qcn6122 binding/firmware family in OpenWrt.

Main unresolved issues:
- RU self-managed regulatory rules contain NO-HE, although the pinned wireless-regdb RU rules do not. The restriction appears through the firmware regulatory PHY bitmap. Looking for guidance on the IPQ5018/QCN6102 BDF/regulatory interaction.
- Some warm reboots fail to return after Wi-Fi is enabled; a cold power cycle boots successfully. Q6 reset/shutdown is only a hypothesis.
- Physical LAN numbering, clean-image reproduction, HE client negotiation and normal installation/sysupgrade are not validated.

The repo is an experimental patch set and evidence summary, not a ready-to-flash release. No personal ART, backups or preconfigured binaries are published. Suggestions from people familiar with IPQ5018 remoteproc/ath11k and the AX55 port would be appreciated.
