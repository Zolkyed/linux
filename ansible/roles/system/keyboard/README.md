# Keyboard

This role installs `keyd`, deploys the system keyboard map, and stores
application-specific mappings in `~/.config/keyd/app.conf`.

Application-specific mappings require `keyd-application-mapper` to receive the
active window from the desktop environment. The user must belong to the `keyd`
group and must log out and back in after being added.

## GNOME

GNOME Wayland requires the keyd GNOME Shell extension. The Arch `keyd` package
provides its source under `/usr/share/keyd/gnome-extension-45`.

Install the extension for the user, ensure its `metadata.json` supports the
installed GNOME Shell version, and enable it:

```bash
mkdir -p ~/.local/share/gnome-shell/extensions
cp -r /usr/share/keyd/gnome-extension-45 \
  ~/.local/share/gnome-shell/extensions/keyd@keyd.rvaiya.github.com
gnome-extensions enable keyd@keyd.rvaiya.github.com
```

Log out and back in if GNOME does not discover the newly installed extension.
The extension creates `$XDG_RUNTIME_DIR/keyd.fifo` and starts
`keyd-application-mapper -d`.

## KDE Plasma

KDE uses KWin's D-Bus interface and does not require a desktop extension.
Install `python-dbus` and start the mapper with the Plasma session:

```bash
sudo pacman -S python-dbus
keyd-application-mapper -d
```

For persistent startup, create `~/.config/autostart/keyd-application-mapper.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=keyd Application Mapper
Exec=keyd-application-mapper -d
NoDisplay=true
X-KDE-autostart-after=panel
```

## Troubleshooting

Run the mapper in the foreground to discover normalized application classes:

```bash
keyd-application-mapper -v
```

GNOME should have an active extension and FIFO; KDE should have `python-dbus`:

```bash
gnome-extensions info keyd@keyd.rvaiya.github.com
ls -l "$XDG_RUNTIME_DIR/keyd.fifo"
pacman -Q python-dbus
```
