# Open investigations

1. RU regulatory domain: both self-managed PHY domains received NO-HE on all 2.4/5 GHz rules. The pinned wireless-regdb RU entry has no NO-HE flag. ath11k maps firmware PHY bitmap bit 5 (NO11AX) to NL80211_RRF_NO_HE. Capture numeric WMI regulatory events to identify why the selected firmware/BDF pair restricts RU. Do not describe this as a kernel regdb ban on channel 36.
2. Mixed country configuration: a later live snapshot had RU on 2.4 GHz and US/HE80 on 5 GHz; both effective PHY domains reported US. The 5 GHz AP was up; the 2.4 GHz AP was absent and hostapd reported failed beacon parameters. This is not a validated configuration or recommended country workaround.
3. Warm reboot: missing network after software reboot with Wi-Fi enabled; cold boot restores it. Q6 shutdown/reset is a hypothesis, not a proven cause. Need paired boot/shutdown diagnostics.
4. Complete LAN jack mapping and individual Ethernet MAC assignment.
5. Automatic native ART extraction and firmware selection in the device profile.
6. Clean reproducible images, long-term stability, client-side HE negotiation and throughput.
7. Validated install, recovery and sysupgrade workflows.
8. End-to-end client internet and DNS: router IP connectivity worked; Cudy DNS returned REFUSED during testing. Do not attribute that upstream DNS issue to ath11k.

No claim of official support, complete Wi-Fi 6 operation or safe general installation is made.

## Follow-up observation (2026-09-30)

A live follow-up found a 5 GHz client reporting HE-MCS 9 / HE-NSS 2 while UCI selected US/HE80 and the effective self-managed PHY rules reported RU/NO-HE. The 2.4 GHz radio was disabled in that snapshot. Hostapd repeatedly logged `Failed to set beacon parameters`. These observations are inconsistent with a simple blanket lack of HE hardware support. They do not establish the cause or prove a regional workaround is stable.

Management disappeared through Ethernet while the physical link remained up. The SSID was reported to appear and then disappear. Management subsequently returned with a short uptime, so the device had started again; the available evidence does not distinguish a user power cycle from an automatic restart or identify where the earlier loss occurred.

Next evidence needed: timestamped UCI/ubus/hostapd/iw snapshots plus numeric firmware regulatory events for both PHYs, and persistent logs around the loss of access. Compare both radios using a consistent country and HT/VHT baseline before isolating the HE failure. No client credentials, personal addresses or packet captures are included.

## OOM evidence and experimental mitigation

Remote syslog captured `hostapd invoked oom-killer` at uptime about287 seconds. A subsequent snapshot at about25 seconds showed MemTotal183220 KiB, MemAvailable14236 KiB, AnonPages7036 KiB and Slab31084 KiB. User processes were small; memory pressure cannot be attributed to hostapd RSS from this evidence. RX page-buffer consumption in ath11k is a leading hypothesis, not yet proven by page-owner tracing.

Added optional patch `953-ath11k-reduce-rx-rings-experimental-256m.patch`, based on Yanko Yankulov's IPQ5018/MR80X commit https://github.com/yanko-yankulov/openwrt-mr80x/commit/ee7747f48999cae66e686d464dceaf838398309e . It reduces RXDMA_BUF4096→512, MON_STATUS1024→128 and MONITOR_BUF4096→128. This is a build-wide experimental limit and can reduce buffering/throughput; it is not a generally validated upstream fix.

Matching6.18.52 modules were compiled and saved to the device overlay after hashes were checked, with original modules retained for rollback. A live module reload freed substantial RAM but Q6 then failed to restart with timeout -110. A subsequent cold boot loaded the optimized module and both APs came up with client association. At about114 seconds, MemAvailable was45688 KiB (an earlier old-module snapshot was14236 KiB). Long-term stability and throughput evaluation remain pending; these snapshots are not a controlled benchmark. No ART, bootloader or kernel FIT change was performed for this optimization.
