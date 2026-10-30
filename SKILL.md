---
name: tv-cleanup
description: Clean up, de-track and speed up smart TVs and streaming sticks on the local network — Android TV / Google TV (debloat + calm launcher), Amazon Fire TV (debloat, privacy menus, ad-blocking DNS, home tidy-up), Samsung Tizen (network remote pairing, privacy and Smart Hub settings by remote keys, HDMI-first boot) — plus whole-home ad-blocking DNS on the router and on every client that bypasses it. Use when the user wants to remove ads/bloatware/tracking from a TV, make a TV or Fire Stick faster, change a TV home screen/dashboard, turn off ACR/viewing data, block ads with DNS, or mentions CleanYourTV, TV Detox, ADB on a TV, Fire Stick, Fire TV, Google TV, Android TV, Samsung Tizen, LG webOS, AdGuard DNS, "pubblicità sulla TV", "pulisci la TV", "velocizza la Fire Stick".
---

# TV Cleanup

One workflow for every TV in the house: find it on the network, pick the right path for its OS,
back up, clean, verify after a reboot, then close the door you opened (ADB / pairing).

Built on two MIT projects, pulled fresh at run time instead of copied:

- **CleanYourTV** (`Gathin23/cleanyourtv`): 360+ tested per-model debloat lists, `tools/disable.sh` with
  backup + recovery record, `tools/restore.sh`, safety checks (HDMI handler, Home, core packages).
- **TV Detox** (`Ansub/tv-detox`): small calm launcher + `install.sh`, `candidates.sh` (plain-English app
  classification), `check.sh`, `undo.sh`.

Helper scripts live in `scripts/` next to this file. Platform details are in `references/`; read the one
for the device before acting.

## 0. Ground rules

- **Disable, never uninstall.** Every change must be reversible with one command; keep the recovery record.
- **Ask before the first destructive batch** unless the user has explicitly said to proceed autonomously.
  Then still back up first, and say what you did afterwards.
- **Never** type the user's passwords into a login page (router, Samsung account, Amazon). Open the page,
  let the user sign in, then continue in the signed-in session. Some harnesses also block changing router
  DNS; if so, fill the form and let the user press Apply.
- **Close the door at the end:** ADB off on Android/Fire (`settings put global adb_enabled 0`), and tell the
  user how to remove the network-remote pairing on Samsung.
- Reply in the user's language.
- **Uninstall only what the user names, and re-read the name.** Before `pm uninstall`, map the user's word to
  the package and its on-screen label (an IPTV app can show as "SKTV" on its banner and "LuckyApp" in the list)
  and save the APK first: `adb shell pm path <pkg>` → `adb pull` (sideloaded apps often have no store to come back from).

## 1. Discover

```bash
python3 -I scripts/discover.py            # scans the /24 of the default interface
python3 -I scripts/discover.py 192.168.1   # or a given /24
```

It reports, per host: open ADB (5555), Samsung remote API (8001/8002 → model, name, power state, Tizen),
LG webOS (3000/3001), Roku ECP (8060 → model), Google Cast (8008/8009 → friendly name), and the MAC vendor
hint. Pick the path:

| Found | OS | Path |
|---|---|---|
| 5555 open, `ro.build.version.name` starts with `Fire OS` | Fire TV | [references/fire-tv.md](references/fire-tv.md) |
| 5555 open, other Android | Android TV / Google TV | [references/android-tv.md](references/android-tv.md) |
| 8001/8002 answers `"OS": "Tizen"` | Samsung | [references/samsung-tizen.md](references/samsung-tizen.md) |
| 3000/3001, 8060, or nothing | LG / Roku / other | Settings-by-remote only + DNS: [references/dns.md](references/dns.md) |
| Fire TV / Android with 5555 closed | — | ADB is off: guide the user to turn it on (below), start `scripts/wait_adb.sh` in the background |

Turning ADB on (only the user can do it, with the physical remote):

- **Fire TV:** Settings → My Fire TV → About → press OK 7× on the device name → back → Developer options →
  ADB debugging ON. If it was on and 5555 is still closed, toggle it OFF and ON again.
- **Android / Google TV:** Settings → Device Preferences → About → press OK 7× on Build → Developer options →
  USB debugging ON (and Network/Wireless debugging if present).
- Then accept "Allow USB debugging?" on the TV, ticking "Always allow from this computer".

`scripts/wait_adb.sh [ip]` waits (default 30 min) until the device is authorised, so you can start it in the
background and carry on as soon as it reports `AUTHORIZED`, without the user having to tell you.

## 1b. Home inventory (every device, every run)

Keep one file per home: `~/.config/tv-cleanup/home.md`. Read it first; it is how the next session knows what
was already done. One section per device:

```markdown
## Tv Salotto — Samsung UE50AU7172 (Tizen 2021) — 192.168.1.170 — MAC 04:b9:e3:…
- Paired as network remote: yes (token in samsung-<ip>.token)
- Done: ACR off, interest ads off (2026-10-29)
- To do: Smart Hub autorun off
- Notes: Anynet+ forwards keys to the Fire Stick when the menu closes
```

Update it after every change (date, what, how to undo). Devices get new IPs from DHCP: match by MAC.
When the user is watching a device ("my daughter is watching"), do not send keys or reboot it: work on
another device or wait, and say so. **Before every batch of keys or app launches, check what is in front**
(`dumpsys activity activities | grep -m1 mResumedActivity`): if it is a player or a streaming app, someone may be
watching — stop and ask, even if the user said to go ahead earlier.

## 2. Fetch the upstream tools (once per session)

```bash
scripts/fetch_upstream.sh       # clones/updates both repos into ~/.cache/tv-cleanup/ and builds tools/venv
```

Read `PROMPT.md` (CleanYourTV) and the README prompt (TV Detox) once: they are the upstream contracts and
change often. Upstream wins over this file when they disagree on a package.

## 3. Identify and back up

```bash
export ANDROID_SERIAL=<ip>:5555
adb shell 'getprop ro.product.model; getprop ro.product.device; getprop ro.build.version.name; getprop ro.build.version.release; getprop ro.build.display.id'
```

Match model + codename + build against `~/.cache/tv-cleanup/cleanyourtv/examples/*/debloat.txt` headers
(`grep -l "<model>" examples/*/debloat.txt`). An exact model+firmware match is a tested list: use it as is.
No exact match → start from the closest list of the same brand/OS and check every package with
`pm list packages` and `dumpsys package` before including it.

`tools/disable.sh` writes the recovery record (`~/.cleanyourtv/recovery-<ip>-*.json`) on its first run;
never delete it. Record any `settings` you change (old → new) in the same session notes.

## 4. Clean, tune, verify

Platform-specific steps are in the reference files. The shape is always:

1. Apply the debloat list (`TV_HOST=<ip> tools/disable.sh <list>`). Respect its skips: they are safety checks
   (HDMI handler, Home, no-permission packages).
2. Privacy menus the shell cannot reach: drive them with `scripts/android_ui.sh` (key + screenshot) and **look
   at every screenshot before the next key**. Confirmation dialogs are common; read them.
3. Speed: animation scales, caches, background apps (platform notes say when *not* to touch animations).
4. Ad-blocking DNS on the device if supported (Android 9+ Private DNS), and on the router ([dns.md](references/dns.md)).
5. Reboot, wait for `sys.boot_completed`, check: disabled count unchanged, Home paints (screenshot), the
   user's main apps open (`dumpsys activity activities | grep mResumedActivity`), network validated,
   ad domains resolve to 0.0.0.0/127.0.0.1.
6. Close ADB and report: what changed, what was kept and why, how to undo.

## 5. Undo

```bash
TV_HOST=<ip> ~/.cache/tv-cleanup/cleanyourtv/tools/restore.sh <same list> [home package]
```

Settings: put back the old values from the notes (`settings put global ...`). DNS: see dns.md.

## Lessons learned (read before driving any TV by remote keys)

- **A closed TV menu forwards keys to the HDMI device.** On Samsung with Anynet+ (HDMI-CEC), arrow/OK keys
  sent after the settings menu timed out went to the Fire Stick and opened an app. Send each menu walk as one
  fast macro (`samsung_remote.py macro ...`), and when you must wait for the user, re-open the menu from the
  top instead of continuing where you think it is.
- **Menu trees move between firmware years.** On a 2021 Samsung (AU7100, Italian UI) "Terms & Privacy" is a
  top-level item after Support, not inside it. Ask the user once for the list of items they see, then encode
  the path as a macro.
- **You cannot see a Samsung screen** (no screenshot API). Keep the user in the loop for verification, or
  prefer settings that are idempotent to send.
- **Fire OS keeps Home, but you can put a clean launcher in front of it** (`scripts/fire_launcher.sh`, see
  fire-tv.md §8): the only way to hide the hero banner and the "Sponsored" row, which DNS cannot block.
- **Fire OS 8: leave animation scales at 1.0** (0.5 breaks the side menu). Fire OS 7: 0.5 is fine and helps.
- **A client with hard-coded DNS bypasses the router** (seen: macOS Wi-Fi DNS set to 8.8.8.8). Always run
  `scripts/dns_check.sh` on the computer you are using, and check browsers for "Secure DNS"/DoH.
