# Editor / pager
export EDITOR='nvim'
export VISUAL='nvim'

# Locale
export LANG='en_US.UTF-8'

# XDG dirs + PATH
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export GOBIN="$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
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

# mise
(( $+commands[mise] )) && eval "$(mise activate zsh)"
