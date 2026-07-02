# Extra
alias yay='paru'
alias update='topgrade'
alias orphans='pacman -Qtdq'

removeorphans() {
  local pkgs
  pkgs=($(pacman -Qtdq))

  if [ ${#pkgs[@]} -eq 0 ]; then
    echo "No orphaned packages found."
    return 0
  fi

  sudo pacman -Rns "${pkgs[@]}"
}

alias speed='speedtest-cli'
alias netscan='sudo nmap -sn 192.168.2.0/24'
alias myip='curl -s https://api.ipify.org; echo'
alias weather='curl wttr.in'
alias ports='sudo ss -tulpn'

alias path='echo -e ${PATH//:/\\n}'
alias untar='tar -zxvf'
alias open='xdg-open'
alias docker-compose='docker compose'
alias journal='journalctl -xe'
alias logs='journalctl -f'

alias yt2mp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --add-metadata --embed-thumbnail'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# File listing and viewing
alias ls='eza -F --color=always --icons=always --group-directories-first'
alias ll='eza -F -l -h -m -u -U --git --color=always --icons=always --group-directories-first'
alias la='eza -a -F --color=always --icons=always --group-directories-first'
alias lt='eza -F -T --level=3 --color=always --icons=always --group-directories-first'
alias cat='bat --wrap auto -n -P'

# File operations
alias mv='mv -v'
alias rm='rm -v'
alias rmd='rm -vr'
alias cp='cp -v'
alias cpd='cp -vr'

# Editor
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias fn='nvim $(fd --type f | fzf)'

# Git
alias gl='git log --oneline --graph --decorate'
alias gs='git status -sb'
alias gd='git diff'
alias gco='git checkout'
