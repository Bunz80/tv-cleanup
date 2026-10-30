# Android TV and Google TV

Full path: debloat **and** replace the home screen.

## 1. Choose the tools

| Need | Use |
|---|---|
| Tested per-model package list | CleanYourTV `examples/<brand-model>/debloat.txt` + `tools/disable.sh` |
| No list for this model | TV Detox `candidates.sh` (classifies every package in plain English), then build a list, checking each package with `dumpsys package` |
| Calm home screen, tiny, no ads | Either launcher: CleanYourTV `launcher/build-and-install.sh` (Apple-TV-like, themes, dock) or TV Detox `install.sh` (apps + HDMI inputs + clock). Offer the user both screenshots (`cleanyourtv/docs`, `tv-detox/docs/home-screen.png`) and let them pick |
| Health check after changes | TV Detox `check.sh`, CleanYourTV `tools/check.py` |
| Undo | CleanYourTV `tools/restore.sh`, TV Detox `undo.sh` |

Both launchers need a JDK + Android build tools; the scripts say what is missing.

## 2. Never disable

Google Play services (`com.google.android.gms`), Play Store, Settings, System UI, setup wizard / `setupwraith`,
keyboard, Bluetooth, HDMI input handler and TV input framework (`com.android.tv`, `*.tvinput*`, the app that
answers `VIEW vnd.android.cursor.item/channel`), package installer, permission controller, ext services,
mainline modules. **Google TV / Chromecast with Google TV: never disable `com.google.android.apps.tv.launcherx`**
(boot loops seen; only a factory reset fixed them). `disable.sh` enforces most of this; don't override its
switches (`FORCE_HOME`, `HANDLERS_ALLOW`, …) unless the list header says so.

## 3. Flow

1. `TV_HOST=<ip> tools/disable.sh <list>` (backup + recovery record on first run).
2. Install the launcher; make it the default Home (`cmd package set-home-activity`); verify the Home button.
3. Animations: 0.5 or off (`settings put global window_animation_scale 0` etc.) unless the list header warns.
4. Sleep after 5 min of inactivity; screensaver ON for OLED (ask the user; check the model).
5. Private DNS (Android 9+): `settings put global private_dns_mode hostname; settings put global private_dns_specifier dns.adguard-dns.com`.
6. Wait 30 s, reboot once, check it boots to the new Home, the user's apps open, free memory before/after.
7. ADB off.

## 4. Brand notes worth knowing

- Xiaomi/MediaTek: `exec-out screencap` prints a banner before the PNG: use `screencap -p /sdcard/x.png` + pull.
- TCL / Hisense Android: keep the brand's Live TV app if the user watches antenna TV.
- Sony Bravia: keep `com.sony.dtv.tvinput*` and the Bravia sound/picture services.
- Philips: Ambilight services are separate packages; keep them if the user likes Ambilight.

Always prefer what the upstream list header says over these notes.
