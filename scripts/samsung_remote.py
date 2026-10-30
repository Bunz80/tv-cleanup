#!/usr/bin/env python3
"""Samsung Tizen network remote (2016+ sets): pair, send keys, run menu macros, list/launch apps.

Needs websocket-client:  python3 -m venv ~/.cache/tv-cleanup/venv && ~/.cache/tv-cleanup/venv/bin/pip install websocket-client

Usage:
  samsung_remote.py <ip> info
  samsung_remote.py <ip> pair [--minutes 10]     # shows "Allow" on the TV; user presses Allow once
  samsung_remote.py <ip> keys KEY_VOLUP KEY_VOLDOWN
  samsung_remote.py <ip> macro <name>             # a named walk from MACROS below
  samsung_remote.py <ip> apps                     # installed apps (appId, name)
  samsung_remote.py <ip> launch <appId>
  samsung_remote.py <ip> macros                   # list macros

The TV has no screenshot API: you cannot see the result. Send a whole menu walk in one fast
connection (a menu left waiting times out, and later arrow keys go to the HDMI device over CEC),
then ask the user to read the screen once.
"""
import argparse
import base64
import json
import os
import ssl
import sys
import time
import urllib.request

try:
    import websocket
except ImportError:
    sys.exit("missing websocket-client: pip install websocket-client (see the docstring)")

NAME = base64.b64encode(b"TV Cleanup").decode()
TOKENS = os.path.expanduser("~/.config/tv-cleanup")

# Menu walks verified on a 2021 UE50AU7172 (Tizen 6, Italian UI). Top-level settings menu on that set:
# Immagine, Audio, Trasmissione, Generali, Supporto, Termini e privacy (focus starts on Immagine).
# Other years/regions differ: confirm the top-level list with the user once, then adapt.
MACROS = {
    "settings": ["KEY_MENU"],
    "privacy-choices": ["KEY_MENU", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN",
                        "KEY_RIGHT", "KEY_ENTER"],
    "privacy-settings": ["KEY_MENU", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN",
                         "KEY_RIGHT", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN", "KEY_ENTER"],
    "general": ["KEY_MENU", "KEY_DOWN", "KEY_DOWN", "KEY_DOWN", "KEY_RIGHT"],
    "close": ["KEY_RETURN", "KEY_RETURN", "KEY_RETURN", "KEY_EXIT"],
}


def token_path(ip: str) -> str:
    return os.path.join(TOKENS, f"samsung-{ip}.token")


def connect(ip: str, timeout: float = 10.0) -> websocket.WebSocket:
    url = f"wss://{ip}:8002/api/v2/channels/samsung.remote.control?name={NAME}"
    if os.path.exists(token_path(ip)):
        url += "&token=" + open(token_path(ip)).read().strip()
    ws = websocket.create_connection(url, sslopt={"cert_reqs": ssl.CERT_NONE}, timeout=timeout)
    msg = json.loads(ws.recv())
    if msg.get("event") != "ms.channel.connect":
        ws.close()
        raise RuntimeError(f"not paired: {msg.get('event')} (run: pair)")
    token = msg.get("data", {}).get("token")
    if token:
        os.makedirs(TOKENS, exist_ok=True)
        with open(token_path(ip), "w") as f:
            f.write(token)
    return ws


def send_keys(ip: str, keys: list[str], delay: float) -> None:
    ws = connect(ip)
    try:
        for key in keys:
            ws.send(json.dumps({"method": "ms.remote.control", "params": {
                "Cmd": "Click", "DataOfCmd": key, "Option": "false", "TypeOfRemote": "SendRemoteKey"}}))
            print(key, flush=True)
            time.sleep(delay)
        time.sleep(1.0)
    finally:
        ws.close()


def info(ip: str) -> None:
    with urllib.request.urlopen(f"http://{ip}:8001/api/v2/", timeout=5) as r:
        d = json.load(r)["device"]
    for k in ("name", "modelName", "model", "OS", "PowerState", "TokenAuthSupport", "developerMode", "networkType"):
        print(f"{k:18} {d.get(k)}")
    print(f"{'paired':18} {os.path.exists(token_path(ip))}")


def pair(ip: str, minutes: int) -> None:
    end = time.time() + minutes * 60
    while time.time() < end:
        try:
            connect(ip, timeout=40).close()
            print("PAIRED, token saved to", token_path(ip))
            return
        except Exception as e:
            print("waiting for Allow on the TV:", e, flush=True)
            time.sleep(3)
    sys.exit("TIMEOUT: nobody pressed Allow. If no prompt shows: Settings > General > External Device "
             "Manager > Device Connection Manager > Access Notification, and unblock 'TV Cleanup' in Device List.")


def apps(ip: str) -> None:
    ws = connect(ip)
    try:
        ws.send(json.dumps({"method": "ms.channel.emit", "params": {
            "event": "ed.installedApp.get", "to": "host"}}))
        end = time.time() + 8
        while time.time() < end:
            msg = json.loads(ws.recv())
            if msg.get("event") == "ed.installedApp.get":
                for a in msg["data"]["data"]:
                    print(f"{a.get('appId'):30} {a.get('name')}")
                return
        print("no app list returned (some firmwares do not answer ed.installedApp.get)")
    finally:
        ws.close()


def launch(ip: str, app_id: str) -> None:
    req = urllib.request.Request(f"http://{ip}:8001/api/v2/applications/{app_id}", method="POST")
    with urllib.request.urlopen(req, timeout=5) as r:
        print(r.status, r.read().decode()[:200])


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("ip")
    p.add_argument("cmd", choices=["info", "pair", "keys", "macro", "macros", "apps", "launch"])
    p.add_argument("args", nargs="*")
    p.add_argument("--minutes", type=int, default=10)
    p.add_argument("--delay", type=float, default=0.8, help="seconds between keys")
    a = p.parse_args()
    if a.cmd == "info":
        info(a.ip)
    elif a.cmd == "pair":
        pair(a.ip, a.minutes)
    elif a.cmd == "keys":
        send_keys(a.ip, a.args, a.delay)
    elif a.cmd == "macro":
        send_keys(a.ip, MACROS[a.args[0]], a.delay)
    elif a.cmd == "macros":
        for k, v in MACROS.items():
            print(f"{k:18} {' '.join(v)}")
    elif a.cmd == "apps":
        apps(a.ip)
    elif a.cmd == "launch":
        launch(a.ip, a.args[0])


if __name__ == "__main__":
    main()
