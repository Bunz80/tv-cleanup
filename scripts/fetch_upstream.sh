#!/usr/bin/env bash
# Clone or update CleanYourTV and TV Detox into ~/.cache/tv-cleanup and prepare CleanYourTV's venv.
set -euo pipefail
CACHE="${TV_CLEANUP_CACHE:-$HOME/.cache/tv-cleanup}"
mkdir -p "$CACHE"
sync_repo() {
  local url="$1" dir="$CACHE/$2"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull -q --ff-only || echo "warning: could not update $2, using the cached copy" >&2
  else
    git clone -q --depth 50 "$url" "$dir"
  fi
  echo "$2: $(git -C "$dir" log -1 --format='%h %cs %s')"
}
sync_repo https://github.com/Gathin23/cleanyourtv.git cleanyourtv
sync_repo https://github.com/Ansub/tv-detox.git tv-detox
if [ ! -x "$CACHE/cleanyourtv/tools/venv/bin/python" ]; then
  python3 -m venv "$CACHE/cleanyourtv/tools/venv"
fi
"$CACHE/cleanyourtv/tools/venv/bin/pip" -q install -r "$CACHE/cleanyourtv/tools/requirements.txt" 2>&1 | grep -v notice || true
echo "ready: $CACHE"
