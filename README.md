# tv-cleanup — a Claude Code skill for ad-free, faster TVs

Point Claude Code at your home network and it cleans every TV it finds:

- **Android TV / Google TV:** debloat with tested per-model lists, a calm ad-free home screen, faster animations.
- **Amazon Fire TV:** debloat, privacy menus, autoplay off, ad-blocking Private DNS, and a clean launcher in front of Amazon's home that hides its ad banner and "Sponsored" row.
- **Samsung Tizen:** pairs as a network remote and walks the privacy and Smart Hub menus for you (ACR, ad
  tracking, diagnostics, autorun), plus HDMI-first boot.
- **The whole home:** ad-blocking DNS on the router, and a check that catches computers and browsers that bypass it.

Everything is turned off, never uninstalled, with a one-line undo.

It stands on two MIT projects, fetched fresh at run time:
[CleanYourTV](https://github.com/Gathin23/cleanyourtv) (360+ tested device lists, safe disable/restore tooling)
and [TV Detox](https://github.com/Ansub/tv-detox) (minimal launcher, app classification, health check).
This skill adds the parts they leave out: device discovery, Fire TV menu automation, Samsung Tizen remote
control, DNS across the house, and lessons from real runs.

## Install

```bash
git clone https://github.com/Bunz80/tv-cleanup ~/.claude/skills/tv-cleanup
```

Requirements: `adb` (Android platform-tools), Python 3.10+, `git`; for Samsung, `pip install websocket-client`.

## Use

In Claude Code, on the same Wi-Fi as the TV:

> Clean up my TVs. I have a Fire TV Stick and a Samsung.

Claude scans the network, tells you the one thing you have to do with the remote (turn on ADB, or press
"Allow" on the Samsung), backs up, cleans, reboots, verifies, and closes ADB again.

## Scripts

| Script | What it does |
|---|---|
| `scripts/discover.py` | Finds ADB, Samsung, LG, Roku and Cast devices on the LAN |
| `scripts/wait_adb.sh` | Waits in the background until ADB is on and authorised |
| `scripts/android_ui.sh` | Key presses + screenshot, for menus the shell cannot reach |
| `scripts/samsung_remote.py` | Samsung pairing, keys, menu macros, app list/launch |
| `scripts/dns_check.sh` | Is ad-blocking DNS really in effect on this computer? |
| `scripts/fire_launcher.sh` | Clean launcher in front of Amazon's Fire TV home (hides the ad banner) |
| `scripts/fetch_upstream.sh` | Clones/updates CleanYourTV and TV Detox |

## Safety

This turns off system apps. Tested lists are the safe path; anything else is checked package by package.
You are responsible for your TV. Turn debugging off afterwards (the skill does it for you).

## License

MIT. CleanYourTV © Gathin and TV Detox © Ansub Khan, both MIT, are used unmodified from their repositories.
