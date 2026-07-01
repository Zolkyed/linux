# x <archive> — extract any common archive format
x() {
  [[ -z "$1" ]] && { echo "Usage: x <archive>"; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1"        ;;
    *.tar.gz|*.tgz)   tar xzf "$1"        ;;
    *.tar.xz)         tar xJf "$1"        ;;
    *.tar.zst)        tar --zstd -xf "$1" ;;
    *.tar)            tar xf "$1"         ;;
    *.bz2)            bunzip2 "$1"        ;;
    *.gz)             gunzip "$1"         ;;
    *.zip)            unzip "$1"          ;;
    *.7z)             7z x "$1"           ;;
    *.xz)             unxz "$1"           ;;
    *.zst)            unzstd "$1"         ;;
    *)                echo "Unknown archive format: $1" ;;
  esac
}

# y
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  cwd="$(command cat -- "$tmp")"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

cd() {
  z "$@" || return
}

alias mkdir='mkdir -p'

search() {
  local file
  file=$(rg --files | fzf)
  [[ -n "$file" ]] && batgrep "$*" "$file" -P
}