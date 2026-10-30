#!/usr/bin/env python3
"""Find TVs and streaming devices on a /24 and say which cleanup path applies.

Usage: python3 -I discover.py [192.168.1]
Read-only: TCP connects and plain HTTP GETs to well-known TV endpoints.
"""
import concurrent.futures as cf
import json
import re
import socket
import ssl
import subprocess
import sys
import urllib.request

PORTS = {
    5555: "adb",
    8001: "samsung",
    8002: "samsung-tls",
    3000: "lg-webos",
    3001: "lg-webos-tls",
    8060: "roku",
    8008: "cast",
    8009: "cast-tls",
}

VENDORS = {
    "68:db:f5": "Amazon", "74:58:f3": "Amazon", "48:5f:2d": "Amazon", "fc:65:de": "Amazon",
    "44:65:0d": "Amazon", "0c:47:c9": "Amazon", "f0:27:2d": "Amazon", "ac:63:be": "Amazon",
    "04:b9:e3": "Samsung", "8c:79:f5": "Samsung", "f4:7b:09": "Samsung", "64:1c:ae": "Samsung",
    "a8:23:fe": "LG", "c8:08:e9": "LG", "78:5d:c8": "LG",
    "b0:a7:37": "Roku", "d8:31:34": "Roku", "ac:3a:7a": "Roku",
    "54:60:09": "Google", "f4:f5:d8": "Google", "1c:f2:9a": "Google",
    "78:a0:3f": "Amazon", "50:02:91": "Espressif (IoT)",
}


def default_prefix() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("1.1.1.1", 53))
        ip = s.getsockname()[0]
    finally:
        s.close()
    return ip.rsplit(".", 1)[0]


def open_ports(ip: str) -> list[int]:
    found = []
    for port in PORTS:
        s = socket.socket()
        s.settimeout(0.4)
        try:
            if s.connect_ex((ip, port)) == 0:
                found.append(port)
        finally:
            s.close()
    return found


def get(url: str, timeout: float = 3.0) -> str:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with urllib.request.urlopen(url, timeout=timeout, context=ctx) as r:
        return r.read(200_000).decode("utf-8", "replace")


def describe(ip: str, ports: list[int]) -> str:
    notes = []
    if 8001 in ports or 8002 in ports:
        try:
            d = json.loads(get(f"http://{ip}:8001/api/v2/"))["device"]
            notes.append(f"Samsung {d.get('OS')} {d.get('modelName')} '{d.get('name')}' power={d.get('PowerState')}")
        except Exception:
            notes.append("Samsung remote API (no metadata)")
    if 8060 in ports:
        try:
            x = get(f"http://{ip}:8060/query/device-info")
            m = re.search(r"<model-name>([^<]*)", x)
            notes.append(f"Roku {m.group(1) if m else ''}".strip())
        except Exception:
            notes.append("Roku ECP")
    if 3000 in ports or 3001 in ports:
        notes.append("LG webOS (SSAP)")
    if 8008 in ports:
        try:
            x = get(f"http://{ip}:8008/ssdp/device-desc.xml")
            m = re.search(r"<friendlyName>([^<]*)", x)
            if m:
                notes.append(f"Cast '{m.group(1)}'")
        except Exception:
            pass
    if 5555 in ports:
        notes.append("ADB open -> Android TV / Fire TV path")
    return "; ".join(notes)


def arp_table() -> dict[str, str]:
    try:
        out = subprocess.run(["arp", "-an"], capture_output=True, text=True, timeout=5).stdout
    except Exception:
        return {}
    table = {}
    for line in out.splitlines():
        m = re.search(r"\(([\d.]+)\) at ([0-9a-f:]+)", line)
        if m:
            mac = ":".join(p.zfill(2) for p in m.group(2).split(":"))
            table[m.group(1)] = mac
    return table


def main() -> None:
    prefix = sys.argv[1] if len(sys.argv) > 1 else default_prefix()
    ips = [f"{prefix}.{n}" for n in range(1, 255)]
    with cf.ThreadPoolExecutor(128) as ex:
        results = [(ip, p) for ip, p in zip(ips, ex.map(open_ports, ips)) if p]
    arp = arp_table()
    if not results:
        print(f"No TV-like ports open on {prefix}.0/24")
    for ip, ports in results:
        mac = arp.get(ip, "")
        vendor = VENDORS.get(mac[:8], "")
        names = ",".join(f"{p}/{PORTS[p]}" for p in ports)
        print(f"{ip:15} {mac:17} {vendor:15} {names}")
        info = describe(ip, ports)
        if info:
            print(f"{'':15} -> {info}")
    amazon = [ip for ip, mac in arp.items() if VENDORS.get(mac[:8], "") == "Amazon" and ip not in dict(results)]
    if amazon:
        print("Amazon devices with no TV port open (Fire TV with ADB off?): " + ", ".join(amazon))


if __name__ == "__main__":
    main()
