set shell := ["bash", "-euo", "pipefail", "-c"]

ANSIBLE_DIR := "ansible"
LOCAL_INVENTORY := "inventory/local.ini"
SSH_INVENTORY := "inventory/ssh.ini"
SETUP_PLAYBOOK := "playbooks/setup.yml"
DOTFILES_PLAYBOOK := "playbooks/dotfiles.yml"
HOSTNAME := `hostname -s`

default:
    @just --list --unsorted

setup-local tags="":
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ LOCAL_INVENTORY }} {{ SETUP_PLAYBOOK }} --limit {{ quote(HOSTNAME) }} -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}

ping-remote host:
    cd {{ ANSIBLE_DIR }} && ansible {{ quote(host) }} -i {{ SSH_INVENTORY }} -m ansible.builtin.ping

setup-remote host=HOSTNAME tags="":
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ SSH_INVENTORY }} {{ SETUP_PLAYBOOK }} --limit {{ quote(host) }} -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}

dotfiles:
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ LOCAL_INVENTORY }} {{ DOTFILES_PLAYBOOK }} --limit {{ quote(HOSTNAME) }} -v --diff
