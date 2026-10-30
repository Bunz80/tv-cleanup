# Amazon Fire TV (Fire OS 5–8)

Debloat works. Amazon's launcher cannot be disabled or replaced as the HOME role (Fire OS ignores a third-party
HOME filter and refuses to disable `com.amazon.tv.launcher`), and its hero banner and "Sponsored" row are drawn
by that launcher, so neither DNS nor debloat removes them. What does work is **sending Amazon's home to a clean
launcher** (section 8): clean, de-track, speed up, block ads by DNS, then put the clean launcher in front.

## 1. Identify

```bash
adb shell 'getprop ro.product.model; getprop ro.product.device; getprop ro.build.version.name'
```

| Model | Codename | Device | CleanYourTV list |
|---|---|---|---|
| AFTSS | sheldon | Fire TV Stick Lite 2020 / Stick 3rd gen | `amazon-fire-tv-stick-lite-2020` |
| AFTMM | mantis | Fire TV Stick 4K 2018 | `amazon-fire-tv-stick-4k-2018` |
| AFTKA | kara | Fire TV Stick 4K Max 2021 | `amazon-fire-tv-stick-4k-max-2021` |
| AFTKM / AFTKRT | karat | Fire TV Stick 4K / 4K Max 2nd gen 2023 (Fire OS 8) | `amazon-fire-tv-stick-4k-2023` |

Other models: `grep -l "<model>" ~/.cache/tv-cleanup/cleanyourtv/examples/amazon-*/debloat.txt`.
Fire OS 5 (Fire TV Box 2015) refuses every `pm` route: stop, nothing can be disabled.

## 2. Debloat

```bash
cd ~/.cache/tv-cleanup/cleanyourtv
TV_HOST=<ip> tools/disable.sh examples/<list>/debloat.txt
```

Keep, even if a list or a user asks otherwise without understanding the cost: launcher, settings, Appstore
(`com.amazon.venezia`), keyboard, remote/Bluetooth, OTA, `com.amazon.tv.oobe` (needed for factory reset),
`com.amazon.imp` on Fire OS 8 (black Home without it), Prime Video if used, casting.

## 3. Privacy menus (synced with the Amazon account, so menus, not `settings put`)

Settings → Preferences → Privacy Settings (IT: Impostazioni → Preferenze → Impostazioni privacy):
- Device Usage Data → OFF (confirm "Turn Off" / "Disattiva" in the dialog)
- Collect App Usage Data → OFF ("Spegni")
- Interest-based Ads → OFF ("Spegni")

Settings → Preferences → Featured Content (IT: Contenuti consigliati):
- Allow Video Autoplay → OFF, Allow Audio Autoplay → OFF

Walk verified on Fire OS 7.7.1.7, Italian UI, starting from `am start -a android.settings.SETTINGS`
(focus starts in the top row; grid: Rete, La mia Fire TV, Profilo, Applicazioni, Suoni e schermo /
Controller, Preferenze, …):

```bash
S=scripts/android_ui.sh
adb shell am start -a android.settings.SETTINGS
$S s1 DPAD_DOWN DPAD_DOWN                 # focus on Rete (Network)
$S s2 DPAD_DOWN DPAD_RIGHT DPAD_CENTER    # Preferenze
$S s3 DPAD_DOWN DPAD_CENTER               # Impostazioni privacy
$S s4 DPAD_DOWN DPAD_DOWN DPAD_CENTER     # Dati di utilizzo del dispositivo -> dialog
$S s5 DPAD_CENTER                         # Disattiva
$S s6 DPAD_DOWN DPAD_CENTER               # Raccogli dati di uso delle app -> dialog
$S s7 DPAD_CENTER DPAD_DOWN DPAD_CENTER   # Spegni, then Pubblicità basata sugli interessi -> dialog
$S s8 DPAD_CENTER                         # Spegni
$S s9 BACK DPAD_DOWN DPAD_DOWN DPAD_DOWN DPAD_CENTER   # Contenuti consigliati
$S s10 DPAD_CENTER                        # video autoplay OFF
$S s11 DPAD_DOWN DPAD_CENTER              # audio autoplay OFF
```

Look at every screenshot before the next line; adapt when the focus is not where expected.

## 4. Speed

- Fire OS 7: `settings put global {window,transition}_animation_scale 0.5; settings put global animator_duration_scale 0.5`.
- **Fire OS 8: leave them at 1.0** (0.5 breaks the ☰ side menu).
- `pm trim-caches 999G`; force-stop heavy apps left in the background (`dumpsys meminfo` → Total PSS by process).
- Report `MemAvailable` before/after from `/proc/meminfo`.

## 5. Ads

- On-device: Fire OS 7+ (Android 9+) honours Private DNS even though the menu is hidden:
  `settings put global private_dns_mode hostname; settings put global private_dns_specifier dns.adguard-dns.com`.
  Undo: `settings put global private_dns_mode off`.
- Verify: `adb shell ping -c1 mads.amazon-adsystem.com` → 127.0.0.1 / 0.0.0.0.
- What DNS cannot remove: the hero banner and sponsored rows come from the launcher's own feed. Turning off
  video autoplay makes them static.
- A VPN app on the stick (e.g. Cloudflare 1.1.1.1/WARP) can override DNS: check `dumpsys connectivity` for a
  `VPN` network and tell the user.

## 6. Tidy Amazon's home ("dashboard")

What the user can still shape on Fire OS:
- **Your apps row:** long-press Home → Apps (or the apps tile) → select an app → Menu (☰) → **Move to front**
  / **Move**; apps outside the first row are hidden from Home. Do this with `android_ui.sh` and screenshots:
  put the user's daily apps first, push utilities (Downloader, VPN, NetGuard) to the end.

  Verified walk (Fire OS 7, IT): `adb shell input keyevent --longpress HOME` → quick menu → `DPAD_RIGHT DPAD_CENTER`
  opens "Applicazioni e giochi". The first row (6 tiles) is what Home shows. Read tile names and positions with
  `adb shell uiautomator dump /sdcard/u.xml && adb shell cat /sdcard/u.xml | grep -o 'text="[^"]*riga[^"]*"'`
  ("Netflix riga 1 colonna 6"). On a tile: `MENU` → options *Sposta, Sposta in primo piano, Maggiori informazioni,
  Rimozione, Disinstalla* → `DPAD_DOWN DPAD_CENTER` = move to front, and focus returns to row 1 col 1.
  Move to front in **reverse** of the wanted order (6th app first, 1st app last). Never press OK on the 4th/5th
  option (remove / uninstall).
- Notifications: Settings → Applications → Appstore → Notifications OFF; Settings → Preferences → Notification
  Settings → Do Not Disturb / per-app OFF for promo apps.
- Featured content autoplay OFF (above).
- Samsung/LG TV in front of the stick: enable HDMI-CEC (Anynet+/SimpLink) so the TV powers on straight into the
  stick: see samsung-tizen.md.

## 7. Verify and close

```bash
adb reboot; # wait for sys.boot_completed=1
adb shell 'pm list packages -d | wc -l; settings get global private_dns_specifier'
scripts/android_ui.sh home HOME           # Home paints
adb shell am start -n com.amazon.firebat/com.amazon.pyrocore.IgnitionActivity   # Prime Video
adb shell dumpsys activity activities | grep -m1 mResumedActivity
adb shell settings put global adb_enabled 0   # last: closes 5555
```

Undo: `TV_HOST=<ip> tools/restore.sh examples/<list>/debloat.txt com.amazon.tv.launcher`.

## 8. Clean launcher in front of Amazon's home (removes the hero banner and "Sponsored" row)

Verified 2026-10-30 on a Fire TV Stick Lite (AFTSS, Fire OS 7.7.1.7 / Android 9), through a reboot.

How it works: CleanYourTV's launcher is installed as a normal app; its accessibility service `HomeKeyService`
with `stock_home_redirect = com.amazon.tv.launcher` sees Amazon's `HomeActivity_vNext` window come up and opens
the clean launcher. After a Home press Android holds other activity starts for ~5 s (app switch protection), so
Amazon's home would stay visible that long: `patches/fire-home-cover.patch` adds a plain full-screen accessibility
overlay on Fire OS that covers it at once and goes as soon as the clean launcher (or any app) is in front.
Upstream keeps "Fire TV Home takeover" out of its repo by policy, so the patch lives here.

```bash
# theme: copy one (glass works well), then set the redirect and the user's apps
cp -R ~/.cache/tv-cleanup/cleanyourtv/themes/glass ~/.config/tv-cleanup/themes/fire-clean
# edit config.json: "stock_home_redirect": "com.amazon.tv.launcher", "restore_key_services": true,
#   "dock_apps": ["com.amazon.firebat", "com.amazon.firetv.youtube", ...]   (installed packages only)
scripts/fire_launcher.sh <stick ip> ~/.config/tv-cleanup/themes/fire-clean
```

Fire TV package names for `dock_apps`: Prime Video `com.amazon.firebat`, YouTube `com.amazon.firetv.youtube`,
Netflix `com.netflix.ninja`, RaiPlay `it.rainet.androidtv`, HBO Max `com.hbo.hbonow`, Disney+ `com.disney.disneyplus`.
Change the dock later by editing the theme and re-running `tools/theme.sh`.

Check: from an app, Home → within ~1.5 s a dark screen (no Amazon home), then the clean launcher
(`dumpsys activity activities | grep mResumedActivity` → `com.gathin.tvhome/.MainActivity`), and the same after a
reboot. Limits: the long-press Home menu and Amazon's Settings still work (open Settings from the launcher's gear);
an Amazon update can stop the redirect, and then the stock home simply comes back.

Undo: `adb shell settings put secure enabled_accessibility_services '""'` (stock home back at once), and
`adb uninstall com.gathin.tvhome` to remove the launcher.
