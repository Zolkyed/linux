# Source the first existing path — package layouts differ between distros
# (Arch: /usr/share/zsh/plugins/<name>/, Fedora/Debian: /usr/share/<name>/).
_source_first() {
  local path
  for path in "$@"; do
    [[ -f "$path" ]] && { source "$path"; return; }
  done
}

# zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
_source_first \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting — must be sourced last
_source_first \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

unfunction _source_first
