# fzf
eval "$(fzf --zsh)"
bindkey '^F' fzf-file-widget

# zoxide
eval "$(zoxide init zsh)"

# atuin
eval "$(atuin init zsh --disable-up-arrow)"

# zsh-autopair
[[ -f /usr/share/zsh/plugins/zsh-autopair/autopair.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-autopair/autopair.zsh

# zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086,underline"
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting — must be sourced last
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f "$HOME/.config/zsh/catppuccin-mocha-zsh-syntax-highlighting.zsh" ]] &&
  source "$HOME/.config/zsh/catppuccin-mocha-zsh-syntax-highlighting.zsh"