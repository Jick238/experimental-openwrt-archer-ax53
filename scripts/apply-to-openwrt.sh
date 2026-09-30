#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tree=${1:?Usage: apply-to-openwrt.sh /path/to/openwrt}
expected=3ab520425b127d66617bfeb1e2805b4f20109f95
actual=$(git -C "$tree" rev-parse HEAD)
[ "$actual" = "$expected" ] || { echo "Expected OpenWrt commit $expected; got $actual" >&2; exit 1; }
git -C "$tree" apply "$repo/patches/0001-archer-ax53-v1-experimental-port.patch"
