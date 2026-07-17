set shell := ["bash", "-cu"]

ANSIBLE_DIR          := "ansible"
ANSIBLE_CONFIG       := "ansible/ansible.cfg"
ANSIBLE_LINT_CONFIG  := "ansible/.ansible-lint.yml"
ANSIBLE_LOG          := "ansible/.ansible/logs/ansible.log"
ANSIBLE_ROLES_PATH   := "ansible/roles"
LOCAL_INVENTORY      := "inventory/local.yml"
SSH_INVENTORY        := "inventory/ssh.yml"
DOTFILES_PLAYBOOK    := "playbooks/dotfiles.yml"
SETUP_PLAYBOOK       := "playbooks/setup.yml"
PLAYBOOKS            := SETUP_PLAYBOOK + " " + DOTFILES_PLAYBOOK
HOSTNAME             := `hostname -s`
YAMLLINT_CONFIG      := ".yamllint"

default:
    @just --list

_clear-log:
    @: > {{ANSIBLE_LOG}}

banner:
    @[[ -t 1 ]] && clear || true
    @printf '%s\n' \
        ' █████╗ ███╗   ██╗███████╗██╗██████╗ ██╗     ███████╗' \
        '██╔══██╗████╗  ██║██╔════╝██║██╔══██╗██║     ██╔════╝' \
        '███████║██╔██╗ ██║███████╗██║██████╔╝██║     █████╗' \
        '██╔══██║██║╚██╗██║╚════██║██║██╔══██╗██║     ██╔══╝' \
        '██║  ██║██║ ╚████║███████║██║██████╔╝███████╗███████╗' \
        '╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝'

setup-local tags="": banner _clear-log
    cd {{ANSIBLE_DIR}} && ansible-playbook -i {{LOCAL_INVENTORY}} {{SETUP_PLAYBOOK}} -l {{HOSTNAME}} -v {{ if tags != "" { "--tags " + tags } else { "" } }}

setup-remote host=`hostname -s` tags="": banner _clear-log
    cd {{ANSIBLE_DIR}} && ansible-playbook -i {{SSH_INVENTORY}} {{SETUP_PLAYBOOK}} -l {{host}} -v {{ if tags != "" { "--tags " + tags } else { "" } }}

dotfiles: banner _clear-log
    cd {{ANSIBLE_DIR}} && ansible-playbook -i {{LOCAL_INVENTORY}} {{DOTFILES_PLAYBOOK}} -l {{HOSTNAME}} -v --diff

check: syntax
    git diff --check
    yamllint -c {{YAMLLINT_CONFIG}} .
    find scripts -name "*.sh" -exec shellcheck {} +
    ANSIBLE_CONFIG={{ANSIBLE_CONFIG}} ANSIBLE_ROLES_PATH={{ANSIBLE_ROLES_PATH}} ansible-lint -c {{ANSIBLE_LINT_CONFIG}} {{ANSIBLE_DIR}}

syntax: _clear-log
    cd {{ANSIBLE_DIR}} && for playbook in {{PLAYBOOKS}}; do ansible-playbook --syntax-check -i {{LOCAL_INVENTORY}} "$playbook"; done
