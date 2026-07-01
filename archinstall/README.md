# Archinstall

## Usage

```bash
iwctl station wlan0 connect "SSID"
curl -fsSL https://raw.githubusercontent.com/Zolkyed/linux/main/scripts/run_archinstall.py | python3
```

## Post-install

```bash
git clone https://github.com/Zolkyed/linux.git && cd linux
./scripts/run_ansibleinstall.sh laptop|desktop
```
