# Archinstall

## Usage

```bash
iwctl station wlan0 connect "SSID"
curl -fsSL https://raw.githubusercontent.com/Zolkyed/linux/main/scripts/bootstrap-archinstall.py | python3
```

## Post-install

Switch to a TTY with <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>F3</kbd>, log in, then bootstrap Ansible.

```bash
git clone https://github.com/Zolkyed/linux.git && cd linux
./scripts/bootstrap-ansible.sh
```
