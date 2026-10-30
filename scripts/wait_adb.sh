#!/usr/bin/env bash
# Wait until a TV's ADB is reachable and authorised. Run it in the background while the user
# turns on ADB and accepts the prompt on the TV.
#
# Usage: wait_adb.sh <ip> [minutes=30]
set -uo pipefail
IP="${1:?usage: wait_adb.sh <ip> [minutes]}"
MINUTES="${2:-30}"
SERIAL="$IP:5555"
end=$(( $(date +%s) + MINUTES * 60 ))
while [ "$(date +%s)" -lt "$end" ]; do
  adb connect "$SERIAL" >/dev/null 2>&1
  state=$(adb -s "$SERIAL" get-state 2>&1)
  case "$state" in
    device) echo "AUTHORIZED $SERIAL"; exit 0 ;;
    *unauthorized*) echo "waiting: accept 'Allow USB debugging?' on the TV" ;;
  esac
  sleep 4
done
echo "TIMEOUT: $SERIAL not authorised after $MINUTES min (ADB off, wrong IP, or prompt not accepted)"
exit 1
