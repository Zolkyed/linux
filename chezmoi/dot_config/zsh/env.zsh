# Editor / pager / browser
export EDITOR='nvim'
export VISUAL='nvim'
export BROWSER='brave-origin'
export PAGER='bat'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Locale
export LANG='en_US.UTF-8'

# XDG dirs + PATH
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export PNPM_HOME="$HOME/.local/share/pnpm"
export GOBIN="$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PNPM_HOME/bin:$PATH"
typeset -U PATH

# Secrets
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000
setopt extended_history hist_ignore_dups hist_expire_dups_first hist_ignore_space hist_verify

setopt auto_cd no_beep
setopt complete_in_word always_to_end

# BAT
export BAT_THEME="Catppuccin Mocha"

# FZF
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#a6e3a1 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#a6e3a1 \
--color=selected-bg:#45475a \
--color=border:#313244,label:#cdd6f4,gutter:#1e1e2e"

# mise
(( $+commands[mise] )) && eval "$(mise activate zsh)"
