#!/usr/bin/env bash
# Press keys on an Android TV / Fire TV and save a screenshot you can look at before the next step.
#
# Usage: ANDROID_SERIAL=<ip>:5555 android_ui.sh <name> [KEY ...]
#   android_ui.sh home HOME
#   android_ui.sh s3 DPAD_DOWN DPAD_RIGHT DPAD_CENTER
# Writes $TV_SHOTS/<name>.png (default ~/.cache/tv-cleanup/shots), resized to 960 px wide,
# and prints the path. Uses screencap to a file + pull: `exec-out screencap` truncates on weak Wi-Fi.
set -euo pipefail
NAME="${1:?usage: android_ui.sh <name> [KEY ...]}"
shift
DIR="${TV_SHOTS:-$HOME/.cache/tv-cleanup/shots}"
mkdir -p "$DIR"
for key in "$@"; do
  adb shell input keyevent "$key"
  sleep "${KEY_DELAY:-1.2}"
done
sleep 1.5
adb shell screencap -p /sdcard/tvc.png
adb pull -q /sdcard/tvc.png "$DIR/$NAME.png"
adb shell rm -f /sdcard/tvc.png
if command -v sips >/dev/null; then
  sips -Z 960 "$DIR/$NAME.png" >/dev/null
elif command -v convert >/dev/null; then
  convert "$DIR/$NAME.png" -resize 960x "$DIR/$NAME.png"
fi
echo "$DIR/$NAME.png"
