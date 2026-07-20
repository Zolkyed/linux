set shell := ["bash", "-euo", "pipefail", "-c"]

ANSIBLE_DIR := "ansible"
LOCAL_INVENTORY := "inventory/local.ini"
SSH_INVENTORY := "inventory/ssh.ini"
HOSTNAME := `hostname -s`

default:
    @just --list --unsorted

ping host="all":
    cd {{ ANSIBLE_DIR }} && ansible {{ quote(host) }} -i {{ SSH_INVENTORY }} -m ansible.builtin.ping

local playbook tags="":
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ LOCAL_INVENTORY }} playbooks/{{ playbook }}.yml --limit {{ quote(HOSTNAME) }} -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}

ssh host playbook tags="":
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ SSH_INVENTORY }} -i {{ host }}, playbooks/{{ playbook }}.yml --limit {{ quote(host) }} -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}

dotfiles:
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ LOCAL_INVENTORY }} playbooks/dotfiles.yml --limit {{ quote(HOSTNAME) }} -v --diff
