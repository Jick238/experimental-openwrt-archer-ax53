# Public worklog

## 2026-09-30 / 2026-10-01 — additional memory reductions and diagnostics

- Built the pinned OpenWrt tree with existing 953 RX reductions plus 954 TX
  completion/monitor reductions and original PR25153 Realtek boot patch.
- Verified FIT kernel/DTB hashes, target configuration, available kernel
  UBI volume capacity and matching module ABI. Saved current kernel,
  modules, environment and configuration privately before installation.
- Updated the active UBI kernel volume and matching modules; kept the old
  read-only rootfs and current overlay configuration. Did not write ART,
  bootloader, stock slot or boot environment in this update. This was a
  device-specific update, not generic sysupgrade: the sysupgrade guard remains.
- One ordinary warm reboot returned. Both APs, Q6 root/PD1/PD2, SSH and
  LuCI were accessible; initial OOM/allocstall and RX/TCL overflow counters
  were zero. Longer-term stability remains open.
- User-applied 802.11r configuration reload succeeded on both interfaces.
  This establishes configuration application, not FT client roaming.
- Detected an early-module issue: the old ROM Realtek driver is loaded
  before overlay. The patched callback is absent in live kallsyms.
  Accordingly, the Ethernet patch is built but not active in this test.
- Installed passive health telemetry without rebooting or reloading Wi-Fi.
  Logs are stored on the Armbian disk, rotated at 8 MiB with seven backups;
  recording pauses below 256 MiB free disk. Previous Cudy logs were archived
  privately. No raw telemetry, device calibration or credentials are public.

### Next evidence

Observe memory and counter trends under normal client traffic, correlate
failures with gateway/Internet/host probes and firmware messages, and perform
controlled throughput comparisons before attributing effects to pool sizes.
Prepare a validated rootfs update to activate the early Realtek module;
one successful boot does not close the intermittent reboot investigation.
