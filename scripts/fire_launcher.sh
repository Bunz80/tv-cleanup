#!/usr/bin/env bash
# Clean launcher on Fire TV: Amazon keeps Home, so build CleanYourTV's launcher with the Fire OS cover patch,
# install it next to Amazon's, and let HomeKeyService send Amazon's home (and its ads) to it.
#
# Usage: fire_launcher.sh <stick ip> <theme folder>
#   theme folder: a CleanYourTV theme (config.json) with "stock_home_redirect": "com.amazon.tv.launcher"
#                 and the user's apps in "dock_apps". Keep it outside the CleanYourTV checkout.
# Undo:  adb shell settings put secure enabled_accessibility_services '""'; adb uninstall com.gathin.tvhome
set -euo pipefail
IP="${1:?usage: fire_launcher.sh <stick ip> <theme folder>}"
THEME="${2:?usage: fire_launcher.sh <stick ip> <theme folder>}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CYT="${TV_CLEANUP_CACHE:-$HOME/.cache/tv-cleanup}/cleanyourtv"
export ANDROID_SERIAL="$IP:5555"

grep -q '"stock_home_redirect": *"com.amazon.tv.launcher"' "$THEME/config.json" \
  || { echo "theme must set stock_home_redirect to com.amazon.tv.launcher" >&2; exit 1; }

cd "$CYT"
if ! grep -q 'FIRE_OS' launcher/app/src/main/java/com/gathin/tvhome/HomeKeyService.java; then
  git apply "$HERE/patches/fire-home-cover.patch" \
    || { echo "patch no longer applies to this CleanYourTV version: rebase patches/fire-home-cover.patch" >&2; exit 1; }
fi

cd launcher
export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 17 2>/dev/null || true)}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
[ -f local.properties ] || echo "sdk.dir=$ANDROID_HOME" > local.properties
./gradlew assembleRelease -q --console=plain

# Amazon's launcher stays Home (it cannot be disabled): install only, and expect the script's
# "Home resolves to com.amazon.tv.launcher" message.
TV_HOST="$IP" STOCK_LAUNCHER=none SKIP_BUILD=1 ./build-and-install.sh || true

cd "$CYT"
TV_HOST="$IP" tools/theme.sh "$THEME"
adb shell pm grant com.gathin.tvhome android.permission.WRITE_SECURE_SETTINGS
adb shell 'cmd appops set com.gathin.tvhome AUTO_START allow 2>/dev/null
  settings put secure enabled_accessibility_services ""; settings put secure accessibility_enabled 0; sleep 1
  settings put secure enabled_accessibility_services com.gathin.tvhome/.HomeKeyService
  settings put secure accessibility_enabled 1'
sleep 3
if adb shell dumpsys accessibility | grep -q 'tvhome\|Tasto Home\|Home key'; then
  echo "HomeKeyService bound."
else
  adb shell dumpsys accessibility | head -5
  echo "WARNING: HomeKeyService does not show as bound; check Settings > Accessibility." >&2
fi
adb shell input keyevent HOME
sleep 7
adb shell dumpsys activity activities | grep -m1 mResumedActivity
