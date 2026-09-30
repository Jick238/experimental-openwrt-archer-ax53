#!/bin/sh
# Passive telemetry only: no reload, reboot, interface or driver changes.
umask 077
STATE=/tmp/ax53-health
mkdir -p "$STATE"
trap '[ -z "$sleeper" ] || kill "$sleeper" 2>/dev/null; exit 0' TERM INT
while :; do
    boot=$(cat /proc/sys/kernel/random/boot_id)
    [ "$(cat "$STATE/boot" 2>/dev/null)" = "$boot" ] || { rm -f "$STATE/previous"; echo "$boot" > "$STATE/boot"; logger -t ax53-health "baseline boot=$boot"; }
    : > "$STATE/current"
    awk '/MemAvailable:|Slab:|SUnreclaim:|AnonPages:/ {printf "%s=%sKiB ",$1,$2}' /proc/meminfo > "$STATE/memory"
    awk '/^oom_kill |^allocstall/ {print "vm."$1,$2}' /proc/vmstat >> "$STATE/current"
    for iface in eth0 wan lan1 lan2 lan3 lan4 phy0-ap0 phy1-ap0; do
        [ -d "/sys/class/net/$iface" ] || continue
        for counter in rx_packets tx_packets rx_dropped tx_dropped rx_errors tx_errors; do
            read -r value < "/sys/class/net/$iface/statistics/$counter"
            echo "$iface.$counter $value" >> "$STATE/current"
        done
    done
    if command -v ethtool >/dev/null 2>&1; then
        ethtool -S eth0 2>/dev/null | awk '
          /[Ee]rror|[Dd]rop|[Uu]nderflow/ {k=$1; sub(/:$/,"",k); if($2 ~ /^[0-9]+$/) print "ethernet."k,$2}
        ' >> "$STATE/current"
    fi
    for radio in /sys/kernel/debug/ath11k/*; do
        [ -r "$radio/soc_dp_stats" ] || continue
        name=${radio##*/}
        awk -v r="$name" '
          /^RXDMA errors:/ {s="rxdma";next} /^REO errors:/ {s="reo";next}
          /^HAL REO errors:/ {s="hal_reo";next} /TCL Ring Full Failures:/ {s="tcl_full";next}
          /^[A-Za-z0-9 ][A-Za-z0-9 ]*: [0-9]+$/ {k=$0; sub(/: [0-9]+$/,"",k); gsub(/ /,"_",k); print r"."s"."k,$NF}
        ' "$radio/soc_dp_stats" >> "$STATE/current"
    done
    touch "$STATE/previous"
    changes=$(awk 'FILENAME==ARGV[1] {old[$1]=$2;next} ($1 in old) {d=$2-old[$1]; if(d>0) printf "%s=+%.0f ",$1,d; else if(d<0) printf "%s=reset ",$1}' "$STATE/previous" "$STATE/current")
    mv "$STATE/current" "$STATE/previous"
    read -r uptime rest < /proc/uptime
    logger -t ax53-health "uptime=$uptime $(cat "$STATE/memory")delta:${changes:-none}"
    for iface in phy0-ap0 phy1-ap0; do
        [ -d "/sys/class/net/$iface" ] || continue
        iw dev "$iface" station dump 2>/dev/null | awk -v i="$iface" '
          /^Station / {n++} /tx retries:/ {retry+=$3} /tx failed:/ {fail+=$3} /rx drop misc:/ {drop+=$4}
          END {printf "iface=%s clients=%d tx_retries_total=%d tx_failed_total=%d rx_drop_misc_total=%d",i,n,retry,fail,drop}' | logger -t ax53-health
    done
    gateway=$(ip -4 route show default | awk 'NR==1 {print $3}')
    for target in "$gateway" 1.1.1.1; do
        [ -n "$target" ] || continue
        result=$(ping -n -c 5 -W 1 "$target" 2>&1 | awk '/packets transmitted|round-trip/ {printf "%s ",$0}')
        logger -t ax53-health "probe=$target ${result:-no-summary}"
    done
    sleep 60 & sleeper=$!; wait "$sleeper"; sleeper=
done
