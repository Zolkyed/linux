set shell := ["bash", "-euo", "pipefail", "-c"]

ANSIBLE_DIR          := "ansible"
LOCAL_INVENTORY      := "inventory/local.yml"
SSH_INVENTORY        := "inventory/ssh.yml"
DOTFILES_PLAYBOOK    := "playbooks/dotfiles.yml"
SETUP_PLAYBOOK       := "playbooks/setup.yml"
HOSTNAME             := `hostname -s`

default:
    @just --list --unsorted

banner:
    @[[ -t 1 ]] && clear || true
    @printf '%s\n' \
        ' █████╗ ███╗   ██╗███████╗██╗██████╗ ██╗     ███████╗' \
        '██╔══██╗████╗  ██║██╔════╝██║██╔══██╗██║     ██╔════╝' \
        '███████║██╔██╗ ██║███████╗██║██████╔╝██║     █████╗' \
        '██╔══██║██║╚██╗██║╚════██║██║██╔══██╗██║     ██╔══╝' \
        '██║  ██║██║ ╚████║███████║██║██████╔╝███████╗███████╗' \
        '╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝'

setup-local tags="": banner
    cd {{ANSIBLE_DIR}} && ansible-playbook -i {{LOCAL_INVENTORY}} {{SETUP_PLAYBOOK}} --limit {{quote(HOSTNAME)}} -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}

ping-remote host:
    cd {{ANSIBLE_DIR}} && ansible {{quote(host)}} -i {{SSH_INVENTORY}} --one-line -m ping

setup-remote host=HOSTNAME tags="": banner
    cd {{ANSIBLE_DIR}} && ansible-playbook -i {{SSH_INVENTORY}} {{SETUP_PLAYBOOK}} --limit {{quote(host)}} -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}

dotfiles: banner
    cd {{ANSIBLE_DIR}} && ansible-playbook -i {{LOCAL_INVENTORY}} {{DOTFILES_PLAYBOOK}} -l {{HOSTNAME}} -v --diff
