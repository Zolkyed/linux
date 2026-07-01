#!/usr/bin/env python3
import sys
import json
import urllib.request
import yaml
from pathlib import Path

config_path = Path.home() / ".config/homectl/config.yml"
if not config_path.exists():
    print(f"Config not found: {config_path}", file=sys.stderr)
    sys.exit(1)

config = yaml.safe_load(config_path.read_text())
base_url = config["assistant_base_url"].rstrip("/")
token = config["assistant_token"]
entity_id = config["assistant_entity_id_fan"]
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json",
}

with urllib.request.urlopen(urllib.request.Request(
    f"{base_url}/api/states/{entity_id}", headers=headers
)) as resp:
    state = json.loads(resp.read())["state"]

if state == "on":
    service = "turn_off"
else:
    service = "turn_on"
payload = json.dumps({"entity_id": entity_id}).encode()

urllib.request.urlopen(urllib.request.Request(
    f"{base_url}/api/services/switch/{service}",
    data=payload,
    headers=headers,
))
