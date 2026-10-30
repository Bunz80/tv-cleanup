#!/usr/bin/env bash
# Is ad-blocking DNS actually in effect on THIS computer? Finds the usual bypasses.
# Read-only. macOS and Linux.
#
# Usage: dns_check.sh [router_ip]
set -uo pipefail
ROUTER="${1:-$( (route -n get default 2>/dev/null | awk '/gateway/{print $2}') || ip route | awk '/default/{print $3; exit}')}"
ADS="doubleclick.net securepubads.g.doubleclick.net pagead2.googlesyndication.com adservice.google.com mads.amazon-adsystem.com"

resolve() { dig +short +time=3 +tries=1 ${2:+@$2} "$1" 2>/dev/null | tail -1; }
blocked() { case "$1" in ""|0.0.0.0|127.0.0.1|::|NXDOMAIN) return 0;; *) return 1;; esac; }

echo "== DNS servers this computer uses"
if [ "$(uname)" = Darwin ]; then
  scutil --dns | awk '/^resolver #1/{f=1} f&&/nameserver/{print "  "$3} /^resolver #2/{exit}'
  while IFS= read -r svc; do
    manual=$(networksetup -getdnsservers "$svc" 2>/dev/null)
    case "$manual" in *"aren't any"*|"") ;; *) echo "  MANUAL DNS on '$svc': $(echo $manual | tr '\n' ' ')  <- overrides the router";; esac
  done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | sed 's/^\*//')
else
  resolvectl dns 2>/dev/null || grep nameserver /etc/resolv.conf
fi

# The DNS the router hands out by DHCP is what every device without a manual override uses. The router's
# own resolver (ROUTER) often still forwards to the ISP even when DHCP advertises a blocker.
DHCP_DNS=""
if [ "$(uname)" = Darwin ]; then
  IFACE=$(route -n get default 2>/dev/null | awk '/interface/{print $2}')
  DHCP_DNS=$(ipconfig getpacket "$IFACE" 2>/dev/null | awk -F'[{},]' '/domain_name_server/{gsub(/ /,"",$2); print $2}')
fi
DHCP_DNS="${DHCP_DNS:-$ROUTER}"
echo "== DHCP hands out: ${DHCP_DNS} (router ${ROUTER})"

echo "== Ad domains: this computer / DHCP DNS"
fail=0
for d in $ADS; do
  local_ans=$(resolve "$d")
  dhcp_ans=$(resolve "$d" "$DHCP_DNS")
  lb=$(blocked "$local_ans" && echo blocked || echo OPEN)
  db=$(blocked "$dhcp_ans" && echo blocked || echo OPEN)
  [ "$lb" = OPEN ] && fail=1
  printf "  %-36s local=%-8s dhcp=%s\n" "$d" "$lb" "$db"
done

echo "== Browser DNS-over-HTTPS (bypasses system DNS when set to a custom provider)"
for prefs in "$HOME/Library/Application Support/Google/Chrome/Local State" \
             "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Local State" \
             "$HOME/Library/Application Support/Microsoft Edge/Local State" \
             "$HOME/.config/google-chrome/Local State"; do
  [ -f "$prefs" ] || continue
  mode=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print(d.get("dns_over_https",{}).get("mode","default"), d.get("dns_over_https",{}).get("templates",""))' "$prefs" 2>/dev/null)
  echo "  $(basename "$(dirname "$prefs")"): ${mode:-default}"
done
echo "  Firefox: check Settings > Privacy > DNS over HTTPS (Max Protection ignores the router)."

if [ "$fail" = 1 ]; then
  echo
  echo "RESULT: ads are NOT blocked on this computer. Fix the MANUAL DNS above (macOS:"
  echo "  networksetup -setdnsservers Wi-Fi empty   # use the router's DNS"
  echo "or set it to the blocker directly), then flush: sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
else
  echo; echo "RESULT: ad domains are blocked on this computer."
fi
