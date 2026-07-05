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

        for (let index = 1; index <= KEYBINDING_COUNT; index++)
            this._addKeybinding(index, this._toggleFavorite.bind(this));
    }

    disable() {
        for (let index = 1; index <= KEYBINDING_COUNT; index++)
            this._addKeybinding(index, this._stockHandler);

        this._stockHandler = null;
        this._settings = null;
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
        const focusedWindow = global.display.focus_window;

        if (app && focusedWindow && app.get_windows().includes(focusedWindow)) {
            Main.overview.hide();
            focusedWindow.minimize();
            return;
        }

        this._stockHandler(display, window, event, binding);
    }
}
