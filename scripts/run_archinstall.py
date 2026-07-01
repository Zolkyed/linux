#!/usr/bin/env python3
from __future__ import annotations

import argparse
import getpass
import importlib
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import uuid

REPO_URL = os.environ.get("REPO_URL", "https://github.com/Zolkyed/dotfiles.git")

HEADER = r"""
  █████╗ ██████╗  ██████╗██╗  ██╗    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
 ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
 ███████║██████╔╝██║     ███████║    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
 ██╔══██║██╔══██╗██║     ██╔══██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
 ██║  ██║██║  ██║╚██████╗██║  ██║    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
 ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
"""


def clear_screen() -> None:
    # Clear scrollback + screen and home the cursor; skip when not a terminal.
    if sys.stderr.isatty():
        sys.stderr.write("\033[3J\033[2J\033[H")
        sys.stderr.flush()


def print_header() -> None:
    clear_screen()
    print(HEADER, file=sys.stderr)


def script_dir() -> str | None:
    # __file__ is absent when piped (curl ... | python3), so signal "no path".
    path = globals().get("__file__")
    return os.path.dirname(os.path.abspath(path)) if path else None


def bootstrap() -> str:
    """Return the repo dir, cloning + re-exec'ing from it when run standalone."""
    here = script_dir()
    if here is not None:
        parent = os.path.dirname(here)
        if os.path.isdir(os.path.join(parent, "archinstall")):
            return parent

    repo_dir = os.environ.get("REPO_DIR", "/root/dotfiles")
    if os.geteuid() == 0 and shutil.which("pacman"):
        subprocess.run(["pacman", "-Sy", "--needed", "--noconfirm", "git"], check=True)

    if not os.path.isdir(os.path.join(repo_dir, ".git")):
        print("==> Cloning dotfiles...", file=sys.stderr)
        subprocess.run(["git", "clone", REPO_URL, repo_dir], check=True)
    else:
        print("==> Updating dotfiles...", file=sys.stderr)
        subprocess.run(["git", "-C", repo_dir, "pull", "--ff-only"], check=True)

    target = os.path.join(repo_dir, "scripts", "run_archinstall.py")
    os.execv(sys.executable, [sys.executable, target, *sys.argv[1:]])


# Interactive helpers

def open_tty():
    try:
        return open("/dev/tty", "r", encoding="utf-8")
    except OSError:
        sys.exit("ERROR: Interactive mode needs a TTY.")


def ask(tty, prompt: str) -> str:
    sys.stderr.write(f"{prompt} ")
    sys.stderr.flush()
    line = tty.readline()
    if not line:
        sys.exit("ERROR: No input.")
    return line.strip()


def error(msg: str) -> None:
    print(f"  ✗ {msg}", file=sys.stderr)


def heading(text: str) -> None:
    print(f"\n❯ {text}", file=sys.stderr)


def select_menu(tty, prompt: str, options: list[str]) -> str:
    heading(prompt)
    width = len(str(len(options)))
    for i, opt in enumerate(options, 1):
        print(f"  {i:>{width}}) {opt}", file=sys.stderr)
    while True:
        line = ask(tty, f"\n  Choice (1-{len(options)}):")
        if line.isdigit() and 1 <= int(line) <= len(options):
            return options[int(line) - 1]
        error("Enter a number from the list.")


def list_disks() -> list[str]:
    out = subprocess.run(
        ["lsblk", "-dnpo", "NAME,TYPE"], capture_output=True, text=True, check=True
    ).stdout
    disks = []
    for line in out.splitlines():
        parts = line.split()
        if len(parts) != 2 or parts[1] != "disk":
            continue
        name = parts[0]
        if name.startswith(("/dev/loop", "/dev/zram", "/dev/ram")):
            continue
        disks.append(name)
    return sorted(disks)


def stable_disk_path(dev: str) -> str:
    """Prefer a stable /dev/disk/by-id path for the selected device."""
    real = os.path.realpath(dev)
    by_id = "/dev/disk/by-id"
    candidates = []
    if os.path.isdir(by_id):
        for name in sorted(os.listdir(by_id)):
            if "-part" in name:
                continue
            path = os.path.join(by_id, name)
            if os.path.islink(path) and os.path.realpath(path) == real:
                candidates.append(path)
    return candidates[0] if candidates else dev


def select_disk(tty) -> str:
    disks = list_disks()
    if not disks:
        sys.exit("ERROR: No target disks found.")
    info = subprocess.run(
        ["lsblk", "-dpo", "NAME,SIZE,MODEL,TRAN,SERIAL,TYPE"],
        capture_output=True, text=True, check=True,
    ).stdout
    # Build the table from the same sorted disk list as the menu, so each row
    # lines up with its choice number (and loop/zram/ram are dropped).
    lines = info.splitlines()
    by_name = {ln.split()[0]: ln for ln in lines[1:] if ln.split()}
    rows = [lines[0]] + [by_name[d] for d in disks if d in by_name]
    heading("Available disks")
    print("\n".join(rows).rstrip(), file=sys.stderr)
    chosen = select_menu(tty, "Select target disk", disks)
    return stable_disk_path(chosen)


def select_desktop(tty) -> str:
    return select_menu(tty, "Select desktop environment", ["KDE Plasma", "GNOME"])


def select_disk_encryption(tty) -> bool:
    choice = select_menu(tty, "Encrypt the root partition?", ["Yes", "No"])
    return choice == "Yes"


def gpu_driver_labels() -> list[str]:
    # Read the labels straight from the installed archinstall so they always
    # match the version on the ISO (the enum has moved modules before).
    for mod in ("archinstall.lib.hardware", "archinstall.lib.models.gfx_driver", "archinstall"):
        try:
            gfx_driver = getattr(importlib.import_module(mod), "GfxDriver")
        except (ImportError, AttributeError):
            continue
        return [d.value for d in gfx_driver]
    return []


def select_gpu(tty) -> str:
    labels = gpu_driver_labels()
    if not labels:
        sys.exit("ERROR: Could not read the GPU driver list from archinstall.")
    return select_menu(tty, "Select GPU driver", labels)


def prompt_text(tty, label: str) -> str:
    while True:
        value = ask(tty, f"\n❯ {label}:")
        if value:
            return value
        error("A value is required.")


def prompt_password() -> str:
    # getpass reads from /dev/tty with echo disabled, so no termios handling is needed.
    heading("Password")
    while True:
        pw = getpass.getpass("  Password: ")
        if not pw:
            error("Password cannot be empty.")
        elif pw != getpass.getpass("  Confirm:  "):
            error("Passwords do not match. Try again.")
        else:
            return pw


def prompt_encryption_passphrase() -> str:
    heading("Disk encryption passphrase")
    while True:
        passphrase = getpass.getpass("  Passphrase: ")
        if not passphrase:
            error("Passphrase cannot be empty.")
        elif passphrase != getpass.getpass("  Confirm:    "):
            error("Passphrases do not match. Try again.")
        else:
            return passphrase


# Config generation


def parse_bool(value: str, variable: str) -> bool:
    normalized = value.strip().lower()
    if normalized in {"1", "true", "yes", "y"}:
        return True
    if normalized in {"0", "false", "no", "n"}:
        return False
    sys.exit(f"ERROR: {variable} must be yes/no, true/false, or 1/0.")

def write_json(dest: str, data: dict) -> None:
    with open(dest, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")


def make_temp_json() -> str:
    fd, path = tempfile.mkstemp(suffix=".json")
    os.close(fd)
    return path


def sz(value: int, unit: str = "MiB") -> dict:
    # Archinstall's Size schema requires sector_size even when the unit is MiB.
    return {"value": value, "unit": unit, "sector_size": {"value": 512, "unit": "B"}}


def build_credentials(dest: str, username: str, password: str,
                      encryption_passphrase: str = "") -> None:
    credentials = {
        "users": [{
            "username": username,
            # Archinstall hashes !password internally:
            # https://github.com/archlinux/archinstall/pull/3276
            "!password": password,
            "groups": ["wheel"],
            "sudo": True,
        }],
    }
    if encryption_passphrase:
        credentials["encryption_password"] = encryption_passphrase
    write_json(dest, credentials)


def build_config(src: str, dest: str, disk: str, desktop: str, gpu: str,
                 hostname: str, encrypt_disk: bool = False) -> None:
    real_disk = os.path.realpath(disk)

    disk_bytes = int(subprocess.run(
        ["blockdev", "--getsize64", real_disk],
        capture_output=True, text=True, check=True,
    ).stdout.strip())

    mib = 1024 ** 2
    boot_start_mib = 1
    boot_size_mib = 4096                            # 4 GiB
    root_start_mib = boot_start_mib + boot_size_mib  # 4097 MiB
    disk_mib = disk_bytes // mib
    root_size_mib = disk_mib - root_start_mib - 1    # 1 MiB gap keeps us clear of backup GPT

    if root_size_mib <= 0:
        sys.exit(f"disk too small: {real_disk}")

    with open(src, encoding="utf-8") as fh:
        data = json.load(fh)

    data["hostname"] = hostname

    root_partition_id = str(uuid.uuid4())
    data["disk_config"] = {
        "config_type": "default_layout",
        "btrfs_options": {"snapshot_config": None},
        "device_modifications": [{
            "device": real_disk,
            "wipe": True,
            "partitions": [
                {
                    "obj_id": str(uuid.uuid4()),
                    "type": "primary", "status": "create",
                    "fs_type": "fat32", "flags": ["boot", "esp"],
                    "mountpoint": "/boot", "mount_options": [], "btrfs": [], "dev_path": None,
                    "start": sz(boot_start_mib),
                    "size":  sz(boot_size_mib),
                },
                {
                    "obj_id": root_partition_id,
                    "type": "primary", "status": "create",
                    "fs_type": "btrfs", "flags": [],
                    "mountpoint": None,
                    "mount_options": ["defaults", "noatime", "compress=zstd"],
                    "dev_path": None,
                    "start": sz(root_start_mib),
                    "size":  sz(root_size_mib),
                    "btrfs": [
                        {"name": "@",      "mountpoint": "/"},
                        {"name": "@home",  "mountpoint": "/home"},
                        {"name": "@root",  "mountpoint": "/root"},
                        {"name": "@srv",   "mountpoint": "/srv"},
                        {"name": "@cache", "mountpoint": "/var/cache"},
                        {"name": "@log",   "mountpoint": "/var/log"},
                        {"name": "@tmp",   "mountpoint": "/var/tmp"},
                    ],
                },
            ],
        }],
    }
    if encrypt_disk:
        data["disk_config"]["disk_encryption"] = {
            "encryption_type": "luks",
            "partitions": [root_partition_id],
            "lvm_volumes": [],
        }

    if desktop == "GNOME":
        data["profile_config"] = {
            "gfx_driver": gpu,
            "greeter": "gdm",
            "profile": {
                "details": ["GNOME"],
                "main": "Desktop",
            },
        }
    elif desktop == "KDE Plasma":
        data["profile_config"] = {
            "gfx_driver": gpu,
            "greeter": "plasma-login-manager",
            "profile": {
                "custom_settings": {"KDE Plasma": {"plasma_flavour": "plasma-meta"}},
                "details": ["KDE Plasma"],
                "main": "Desktop",
            },
        }
    else:
        sys.exit(f"ERROR: Unknown desktop environment: {desktop}")

    write_json(dest, data)


def is_block_device(path: str) -> bool:
    try:
        return stat.S_ISBLK(os.stat(path).st_mode)
    except OSError:
        return False


# Main

def main() -> None:
    repo_dir = bootstrap()

    parser = argparse.ArgumentParser(description="Run archinstall with this repo's config.")
    parser.add_argument("target_disk", nargs="?", help="Target disk (e.g. /dev/sda)")
    args = parser.parse_args()

    tty = open_tty()
    print_header()

    target_disk = os.environ.get("ARCHINSTALL_DISK", args.target_disk or "")
    desktop_env = os.environ.get("ARCHINSTALL_DESKTOP", "")
    gpu_driver = os.environ.get("ARCHINSTALL_GPU", "")
    username = os.environ.get("ARCHINSTALL_USERNAME", "")
    password = os.environ.get("ARCHINSTALL_PASSWORD", "")
    hostname = os.environ.get("ARCHINSTALL_HOSTNAME", "")
    encryption_setting = os.environ.get("ARCHINSTALL_ENCRYPTION", "")
    encryption_passphrase = os.environ.get("ARCHINSTALL_ENCRYPTION_PASSWORD", "")

    if not target_disk:
        target_disk = select_disk(tty)  # The menu only offers real disks.
    elif not is_block_device(target_disk):
        sys.exit(f"ERROR: Not a block device: {target_disk}")
    encrypt_disk = (
        parse_bool(encryption_setting, "ARCHINSTALL_ENCRYPTION")
        if encryption_setting else select_disk_encryption(tty)
    )
    if encrypt_disk and not encryption_passphrase:
        encryption_passphrase = prompt_encryption_passphrase()
    if not encrypt_disk:
        encryption_passphrase = ""
    if not desktop_env:
        desktop_env = select_desktop(tty)
    if not gpu_driver:
        gpu_driver = select_gpu(tty)
    if not username:
        username = prompt_text(tty, "Username")
    if not password:
        password = prompt_password()
    if not hostname:
        hostname = prompt_text(tty, "Hostname")

    config = os.path.join(repo_dir, "archinstall", "user_configuration.json")
    if not os.path.isfile(config):
        sys.exit(f"ERROR: Missing: {config}")

    tmp_config = make_temp_json()
    tmp_creds = make_temp_json()
    try:
        build_config(
            config, tmp_config, target_disk, desktop_env, gpu_driver, hostname,
            encrypt_disk,
        )
        build_credentials(tmp_creds, username, password, encryption_passphrase)

        rows = [
            ("Hostname", hostname),
            ("Username", username),
            ("Target disk", target_disk),
            ("Encryption", "LUKS" if encrypt_disk else "Disabled"),
            ("Desktop", desktop_env),
            ("GPU driver", gpu_driver),
        ]
        heading("Summary")
        for label, value in rows:
            print(f"  {label:<12} {value}", file=sys.stderr)

        print("\n❯ Opening the archinstall TUI — review and start the install.",
              file=sys.stderr)
        subprocess.run(
            ["archinstall", "--config", tmp_config, "--creds", tmp_creds],
            stdin=tty, check=False,
        )
    finally:
        for tmp in (tmp_config, tmp_creds):
            try:
                os.unlink(tmp)
            except OSError:
                pass


if __name__ == "__main__":
    main()
