#!/usr/bin/env python3
import sys
import urllib.request
import urllib.error
import yaml
from pathlib import Path

config_path = Path.home() / ".config/homectl/config.yml"
if not config_path.exists():
    print(f"Config not found: {config_path}", file=sys.stderr)
    sys.exit(1)

config = yaml.safe_load(config_path.read_text())

try:
    urllib.request.urlopen(config["webhook_url"])
except urllib.error.URLError as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
