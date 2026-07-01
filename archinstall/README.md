# Archinstall

## Usage

```bash
iwctl station wlan0 connect "SSID"
curl -fsSL https://raw.githubusercontent.com/Zolkyed/dotfiles/main/scripts/run_archinstall.py | python3
```

## Post-install

```bash
git clone https://github.com/Zolkyed/dotfiles.git && cd dotfiles
./scripts/run_ansibleinstall.sh laptop|desktop
```