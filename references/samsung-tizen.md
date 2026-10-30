# Samsung Tizen (2016+)

No ADB, no shell, no screenshot, no Home replacement on retail firmware. What *does* work:

| Lever | How | Effect |
|---|---|---|
| Network remote | `samsung_remote.py <ip> pair`, then `keys` / `macro` | Drive every menu as if holding the remote |
| Privacy toggles | Settings → Terms & Privacy (menus below) | Turn off ACR ("viewing information services"), interest-based ads, diagnostics, voice |
| Smart Hub autorun | Settings → General → Smart Features | TV starts on the last input (e.g. the Fire Stick), not Samsung's ad home |
| HDMI-CEC (Anynet+) | Settings → General → External Device Manager → Anynet+ ON | Fire Stick/console wakes the TV and switches to its input |
| App launch | `samsung_remote.py <ip> launch <appId>` / `apps` | Open apps directly; list installed apps |
| DNS | Router (see dns.md); Tizen has no per-device DNS UI on most models except Network → IP settings → DNS manual | Blocks Samsung Ads / tracking domains |
| Developer Mode + sdb (optional, advanced) | Apps → type 1-2-3-4-5 → Developer mode ON, Host PC IP = this computer; Tizen Studio `sdb connect <ip>` | Install a signed custom web app (your own dashboard). It does **not** take the Home button |

## 1. Pair

```bash
python3 -I scripts/samsung_remote.py <ip> info
python3 -I scripts/samsung_remote.py <ip> pair      # user presses "Allow" once on the TV
```

`ms.channel.timeOut` = the prompt was shown and nobody answered. No prompt at all → Settings → General →
External Device Manager → Device Connection Manager → Access Notification "First time only", and remove a
blocked entry from Device List.

Test with an effect the user can see without menus: `keys KEY_VOLUP KEY_VOLDOWN` ("did the volume bar appear?").

## 2. Driving menus blind, safely

- **Send whole walks as one macro.** A settings menu left waiting closes itself; keys that arrive after that go
  to the active HDMI device over CEC (seen: arrows + OK opened RaiPlay on the Fire Stick).
- **Ask the user for the top-level list once** ("Picture, Sound, Broadcasting, General, Support, Terms…") and
  which item is highlighted. Encode it in `MACROS` in `samsung_remote.py`.
- **Prefer reads before toggles.** For checkboxes/toggles, ask "ticked or empty?" before pressing OK: a second
  OK switches it back on.
- Avoid number keys and anything under Support → Device Care / Self Diagnosis → Reset (PIN 0000 factory reset).
- `KEY_HOME` while an HDMI device is active may be forwarded to that device; `KEY_MENU` opens Samsung settings.

## 3. What to turn off (2021 Tizen 6, Italian UI; English in brackets)

Verified on UE50AU7172 (model string `21_KANTSU2E_UHD_BASIC`). The top level of Settings is
Immagine, Audio, Trasmissione, Generali, Supporto, **Termini e privacy** (Terms & Privacy is a top-level item
on this firmware, not inside Support).

1. **Termini e privacy → Scelte sulla privacy** (Privacy Choices):
   - "Accetto i servizi basati sulle informazioni di visualizzazione" (Viewing Information Services = ACR) → empty
   - "Accetto i contenuti/pubblicità basati sugli interessi" (Interest-Based Ads) → empty
   - leave "Smart Hub Terms" as is unless the user wants no Smart Hub at all (that disables the app store)
2. **Termini e privacy → Impostazioni privacy → Migliora la tua esperienza** (Improve your experience /
   diagnostics) → OFF
3. **Generali → Funzioni Smart** (Smart Features):
   - Esecuzione automatica Smart Hub (Autorun Smart Hub) → OFF
   - Esecuzione automatica ultima app (Autorun Last App) → OFF if the user wants the TV to open on the HDMI input
4. **Generali → Voce** → Wake-up / Bixby voice OFF if the user does not use voice.
5. **Generali → Gestione dispositivi esterni → Anynet+ (HDMI-CEC)** → ON when a Fire Stick / console is the
   main source.

Newer firmware (2022+, Tizen 7+): the same items live under Settings → All Settings → General & Privacy →
Terms & Privacy, and "Privacy Choices" may show toggles instead of checkboxes.

## 4. Improving the Samsung "dashboard"

Samsung Home cannot be replaced. What helps:
- **Make it irrelevant:** Autorun Smart Hub OFF + Anynet+ ON → the TV wakes straight into the stick, whose home
  you *can* tidy.
- **Reorder / remove apps in the Smart Hub bar:** Home → select app → Down → Move / Remove. Ask the user to read
  the bar once, then send the moves as a macro.
- **Router DNS** removes most Samsung Ads banners and the Samsung TV Plus promo tiles' tracking.
- Optional: a custom Tizen web app (Developer Mode + Tizen Studio) as a launcher you open with one key. Treat it as
  a project of its own; see CleanYourTV `docs/devices/samsung-tizen.md` (DU7000 notes).

## 5. Close

Tell the user how to revoke the pairing: General → External Device Manager → Device Connection Manager →
Device List → "TV Cleanup" → Delete. Tokens are in `~/.config/tv-cleanup/samsung-<ip>.token`.
