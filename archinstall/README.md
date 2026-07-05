# Archinstall

## Usage

```bash
iwctl station wlan0 connect "SSID"
curl -fsSL https://raw.githubusercontent.com/Zolkyed/linux/main/scripts/run_archinstall.py | python3
```

## Post-install

Switch to a TTY with <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>F3</kbd>, log in, then run the Ansible installer. This prevents desktop-session changes from interrupting the installation.

```bash
git clone https://github.com/Zolkyed/linux.git && cd linux
./scripts/run_ansibleinstall.sh laptop|desktop
```
