# Hardware findings

## Ethernet

RTL8367S is detected by the realtek/rtl8365mb DSA driver at MDIO1 address 0x1d. Switch CPU port 6 connects to gmac1 through 2500base-x / HSGMII. MDIO pins: GPIO36 MDC, GPIO37 MDIO. No unverified GPIO39 reset is asserted. Physical LAN numbering still needs a jack-by-jack check.

## Native calibration

The original vendor `art_backup.tgz` contains ART.bin (1 MiB) and ART.md5. Extracted ART.bin matched the raw AX53 `0:art` MTD backup byte for byte. Partition capitalization differs between documentation and the live SMEM label.

| Radio | ART offset | Extracted size | Tested firmware directory / filenames |
| --- | --- | --- | --- |
| IPQ5018 2.4 GHz | 0x1000 | 0x20000 (131072 bytes) | ath11k/IPQ5018/hw1.0/board.bin and cal-ahb-c000000.wifi.bin |
| QCN6102 family 5 GHz | 0x26800 | 0x20000 (131072 bytes) | ath11k/QCN6122/hw1.0/board.bin and cal-ahb-b00a040.wifi.bin |

Both windows begin with bytes 01 00 04 04; XOR of little-endian 16-bit words over each whole 0x20000-byte window is 0xffff. This is structural evidence, not a complete reverse engineering of the EEPROM format. Both radios subsequently probed and broadcast using these native files. Raw calibration is not published.

The usual ath11k_remove_regdomain helper would make no change to these exact candidates: offset 0x34 is already zero and the helper only clears matching copies. This does not prove all regulatory fields have been decoded.

## Q6 / firmware

Enable q6v5_wcss, wifi (PD1) and wifi1 (PD2); wifi2 stays disabled. Q6 boot-args: `<1 4 3 15 0 0 2 4 2 27 0 0>`. Both radios use memory mode 2. BDF addresses: 0x4c400000 and 0x4d100000. External M3 dump address: 0x4df00000.

Firmware tested: WLAN.HK.2.7.0.1-01744-QCAHKSWPL_SILICONZ-1 from OpenWrt ath11k-firmware-ipq5018-qcn6122. Exact external silicon SKU has not been independently decoded from live QMI identifiers.

## Boot observations

The tested U-Boot required staged `bootm start`, `loados`, `ramdisk`, `fdt`, `prep`, `go`. A simple bootm invocation did not produce the same result; root cause is unresolved.

TFTP required explicit Ethernet initialization in the inspected vendor bootloader. A hard-coded Thumb entry point was guarded against the exact inspected bootloader bytes. It is deliberately not offered as a universal boot command.

NAND boot from rootfs/mtd11 with SquashFS and UBIFS overlay succeeded. Stock rootfs_1 was kept, but byte identity of that slot after boot activity was not proven. Cold boot with the Wi-Fi-enabled kernel succeeded; some warm reboots did not return to management.
