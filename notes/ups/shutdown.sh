#!/bin/sh
# /etc/nut/upssched-cmd
# Called by upssched. Triggered after the timer in upssched.conf fires.
#
# Shutdown flow:
#   ONBATT  → upssched starts 60s timer → this script runs "onbatt" if timer expires
#   ONLINE  → upssched cancels the timer → no shutdown
#   LOWBATT → immediate shutdown regardless of timer (battery critically low)
#
# pve-guests.service handles graceful VM stop during host shutdown — no extra steps needed.

case "$1" in
  onbatt)
    logger -t nut-shutdown "UPS on battery for 60s — initiating graceful shutdown"
    /sbin/shutdown -h now "UPS battery: power outage exceeded 60s"
    ;;
  lowbatt)
    logger -t nut-shutdown "UPS battery critically low — immediate graceful shutdown"
    /sbin/shutdown -h now "UPS battery critical"
    ;;
  *)
    logger -t nut-shutdown "upssched-cmd called with unknown event: $1"
    ;;
esac
