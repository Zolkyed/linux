import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as AppFavorites from 'resource:///org/gnome/shell/ui/appFavorites.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const KEYBINDING_SCHEMA = 'org.gnome.shell.keybindings';
const KEYBINDING_PREFIX = 'switch-to-application-';
const KEYBINDING_COUNT = 9;

export default class ToggleFavoriteExtension extends Extension {
    enable() {
        this._settings = new Gio.Settings({schema_id: KEYBINDING_SCHEMA});
        this._stockHandler = Main.wm._switchToApplication.bind(Main.wm);
        this._cycle = null;

        for (let index = 1; index <= KEYBINDING_COUNT; index++)
            this._addKeybinding(index, this._toggleFavorite.bind(this));
    }

    disable() {
        for (let index = 1; index <= KEYBINDING_COUNT; index++)
            this._addKeybinding(index, this._stockHandler);

        this._stockHandler = null;
        this._settings = null;
        this._cycle = null;
    }

    _addKeybinding(index, handler) {
        const name = `${KEYBINDING_PREFIX}${index}`;

        Main.wm.removeKeybinding(name);
        Main.wm.addKeybinding(
            name,
            this._settings,
            Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
            handler
        );
    }

    _toggleFavorite(display, window, event, binding) {
        const target = Number.parseInt(binding.get_name().split('-').at(-1), 10);
        const app = AppFavorites.getAppFavorites().getFavorites()[target - 1];

        if (!app)
            return;

        const windows = app.get_windows();
        const focusedWindow = global.display.focus_window;

        Main.overview.hide();

        // A single-window app toggles like a taskbar button. For a grouped app,
        // repeated presses cycle through its windows instead of minimizing one.
        if (focusedWindow && windows.includes(focusedWindow)) {
            if (windows.length === 1) {
                focusedWindow.minimize();
                this._cycle = null;
                return;
            }

            const sameCycle = this._cycle?.app === app &&
                this._cycle.windows.length === windows.length &&
                this._cycle.windows.every(cycleWindow => windows.includes(cycleWindow)) &&
                this._cycle.windows[this._cycle.index] === focusedWindow;

            if (!sameCycle) {
                this._cycle = {
                    app,
                    windows: [focusedWindow, ...windows.filter(appWindow => appWindow !== focusedWindow)],
                    index: 0,
                };
            }

            this._cycle.index = (this._cycle.index + 1) % this._cycle.windows.length;
            Main.activateWindow(this._cycle.windows[this._cycle.index], event.get_time());
        } else if (windows.length > 0) {
            this._cycle = {app, windows: [...windows], index: 0};
            Main.activateWindow(windows[0], event.get_time());
        } else {
            this._cycle = null;
            app.activate_full(-1, event.get_time());
        }
    }
}
