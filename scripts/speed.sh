#!/usr/bin/env bash
# Quick tune-up for an Android TV / Fire TV over ADB: free RAM and cached files without touching settings or data.
# Safe to run any time (e.g. weekly, or when the stick feels slow). Nothing is disabled or uninstalled.
#
# Usage: speed.sh <ip> [--deep]
#   default: clear every app's cache files, stop background apps, compact memory
#   --deep:  also recompile apps for speed (takes 5-15 min once; worth it after big app updates)
set -euo pipefail
IP="${1:?usage: speed.sh <ip> [--deep]}"
export ANDROID_SERIAL="$IP:5555"
adb connect "$ANDROID_SERIAL" >/dev/null 2>&1 || true

mem() { adb shell grep MemAvailable /proc/meminfo | awk '{printf "%d MB", $2/1024}'; }
disk() { adb shell df -h /data | tail -1 | awk '{print $4" free of "$2}'; }
echo "before: RAM free $(mem), storage $(disk)"

FRONT=$(adb shell dumpsys activity activities | grep -m1 mResumedActivity | grep -oE '[a-z][a-z0-9_.]+/' | tr -d '/')
echo "in front (left alone): ${FRONT:-unknown}"

# Cache files of every app (Android deletes cache dirs until this much is free; data and logins stay).
adb shell pm trim-caches 999G
# Background processes only: the app in front, Home and system services are not killed.
adb shell am kill-all
# Third-party apps left running in the background (streaming apps keep 100+ MB each).
for pkg in $(adb shell pm list packages -3 | sed 's/package://' | tr -d '\r'); do
  case "$pkg" in "$FRONT"|com.gathin.tvhome|*overlay*) continue ;; esac
  adb shell am force-stop "$pkg"
done
# Prime Video on Fire TV is a system app that stays resident after use.
[ "$FRONT" = com.amazon.firebat ] || adb shell am force-stop com.amazon.firebat 2>/dev/null || true
# Ask Android to trim memory of what is left.
adb shell 'for p in $(pidof com.amazon.tv.launcher com.gathin.tvhome 2>/dev/null); do am send-trim-memory $p RUNNING_LOW 2>/dev/null; done' || true

if [ "${2:-}" = --deep ]; then
  echo "recompiling apps for speed (bg-dexopt)..."
  adb shell cmd package bg-dexopt-job || adb shell cmd package compile -m speed-profile -a
fi
sleep 3
echo "after:  RAM free $(mem), storage $(disk)"
