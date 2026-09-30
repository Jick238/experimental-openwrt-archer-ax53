# Passive health monitoring

`ax53-health.sh` runs under OpenWrt procd. Each cycle takes a snapshot then
sends five small ICMP probes to the default IPv4 gateway and a public target,
followed by a 60-second pause. It reports:

- uptime, available/anonymous/slab memory and OOM/allocstall deltas;
- per-interface packet/error/drop deltas and optional ethtool hardware
  error/drop/underflow deltas (including the switch CPU port);
- ath11k RXDMA, REO and TCL/full/completion-related counters exposed by
  `soc_dp_stats` (firmware-internal counters may not all be available);
- aggregate client retry/failure/drop totals without client MACs;
- loss and RTT separately for the gateway and Internet target.

It never reloads Wi-Fi, unloads modules, changes network configuration or
reboots. Temporary state is overwritten each cycle, not accumulated.
The first sample is a baseline. Counters that decrease are marked reset;
station totals can change when clients leave. Missing counters are not
proof of absence of a fault. Unsupported station counters may stay zero.

Install as `/usr/sbin/ax53-health` with its init file at
`/etc/init.d/ax53-health`, both executable, then enable/start the service.
Use OpenWrt's existing remote UDP syslog settings for the destination.

## Armbian disk receiver

Install `receiver.py` at `/usr/local/lib/ax53-monitor/receiver.py` and the
provided systemd unit. Define `AX53_BIND_IP`, `AX53_SENDER_IP`, and optional
`AX53_LOG_PORT=5514` in `/etc/ax53-log-receiver.conf` (private, mode0600).
The receiver accepts the chosen sender and independently probes the router
from Armbian every ~64 seconds. Its systemd dynamic user writes private files
under `/var/lib/ax53-monitor`; this must be on disk, not RAM-backed `/var/log`.
No packages are installed by these scripts; Python3 and ping are required.

The active file plus seven rotated files use approximately 64 MiB maximum
(plus at most one log record). Writes pause below 256 MiB free disk. Archived
pre-migration logs are separate fixed files. Service memory is capped at
48 MiB on Armbian. Logs are diagnostic/private and may contain firmware or
hostapd identifiers. Restrict access and do not commit them to the repository.
UDP delivery is best effort and unauthenticated; filtering source IP is
not cryptographic authentication. An Archer crash may lose its final messages;
Armbian reachability probes continue independently.

Router-to-gateway/internet probes do **not** traverse a Wi-Fi client's radio
path. Client-side loss and throughput require measurements on that client.
Retry/FCS/drop increases can reflect RF noise or normal traffic, not solely
small queues. Compare counter deltas, traffic volume and firmware warnings;
causal attribution requires a controlled before/after test.

Stop/disable `ax53-health` to remove collection, and stop/disable
`ax53-log-receiver` to stop reception. Neither action changes forwarding.
Receiver timestamps use the Armbian clock; sender timestamps use the router
clock. Check clock offsets and use uptime to distinguish restarts.
