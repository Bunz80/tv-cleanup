# Ad-blocking DNS for the whole home

DNS blocking removes ad and tracking *domains* everywhere at once (TVs, phones, PCs). It cannot remove ads that
are served from the same domain as the content (YouTube video ads, Amazon's own home rows, many news-site
first-party ads), so set expectations.

## Providers (no account needed)

| Provider | IPv4 | Private DNS / DoT hostname |
|---|---|---|
| AdGuard DNS (default) | 94.140.14.14, 94.140.15.15 | dns.adguard-dns.com |
| AdGuard Family (also adult content) | 94.140.14.15, 94.140.15.16 | family.adguard-dns.com |
| Mullvad adblock | 194.242.2.3 | adblock.dns.mullvad.net |
| NextDNS (custom lists, account) | per-profile | <id>.dns.nextdns.io |

Self-hosted (Pi-hole / AdGuard Home) gives lists and per-device stats; suggest it when the user wants control.

## Router

Change the DNS the router hands out with DHCP (LAN settings), not the WAN DNS, so devices use the blocker
directly. Before changing, **write down the current value** (e.g. "DNS Proxy" / "From ISP") for the undo.

- **Zyxel (WindTre "Wind3 HUB", many ISP Zyxels):** Network → Rete locale LAN (Home Networking) → Configurazione
  LAN → Valori DNS: Statico → Server DNS 1/2 → Applica. Undo: back to "DNS Proxy".
- **FRITZ!Box:** Internet → Account Information → DNS Server → Use other DNSv4 servers.
- **TP-Link:** Advanced → Network → DHCP Server → Primary/Secondary DNS.
- **TIM/Vodafone/Fastweb ISP routers:** often lock DNS. Then set DNS per device (Private DNS on Android,
  network settings on TV/PC) or put a Pi-hole/AdGuard Home on the LAN as DHCP server.

The user logs in to the router; you can fill the form. Some agent harnesses block pressing Apply on a DNS change:
then the user clicks it.

Devices pick up the new DNS when their DHCP lease renews: reconnect Wi-Fi or reboot them.

## Clients that bypass the router (check every time)

Run `scripts/dns_check.sh` on the computer. Usual culprits:
- **Manual DNS on the computer** (macOS: System Settings → Network → Wi-Fi → Details → DNS; seen: 8.8.8.8).
  Fix: `networksetup -setdnsservers Wi-Fi empty` (use the router) or set the blocker directly.
- **Browser Secure DNS / DoH** set to a custom provider (Chrome/Edge/Brave "Use secure DNS: with Google/Cloudflare",
  Firefox "Max Protection"): set it to "With your current service provider" or to the blocker's DoH URL
  (`https://dns.adguard-dns.com/dns-query`).
- **VPN apps** (WARP/1.1.1.1, corporate VPNs, iCloud Private Relay in Safari) use their own DNS.
- **Android phones** with Private DNS set to another provider.
- Caches: macOS `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`; restart the browser.

For ads that DNS cannot touch on a computer, recommend a content blocker extension (uBlock Origin / uBlock Origin
Lite, AdGuard) in addition to DNS.
