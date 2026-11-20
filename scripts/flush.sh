#!/usr/bin/env bash
# Flash using debug probe
# cargo flash --bin wifi_blinky
# Flash using picotool
# cargo build --release --bin wifi_blinky
#
# Put the Pico into BOOTSEL mode, then flash
# picotool load -x target/thumbv6m-none-eabi/release/wifi_blinky
# Put the Pico into BOOTSEL mode, then flash
# picotool load -x target/thumbv6m-none-eabi/release/wifi_blinky
# ./flash.sh
#Usage:
#
# ./flash.sh probe wifi_blinky
# ./flash.sh pico wifi_blinky

set -euo pipefail

METHOD="${1:-probe}"
BIN="${2:-wifi_blinky}"

case "$METHOD" in
  probe)
    cargo run --release --bin "$BIN"
    ;;
  pico)
    cargo build --release --bin "$BIN"
    picotool load -x "target/thumbv6m-none-eabi/release/$BIN"
    ;;
  *)
    echo "Usage: $0 {probe|pico} [binary]"
    exit 1
    ;;
esac
