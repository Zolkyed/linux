set shell := ["bash", "-euo", "pipefail", "-c"]

ANSIBLE_DIR := "ansible"
LOCAL_INVENTORY := "inventory/local.ini"
SSH_INVENTORY := "inventory/ssh.ini"
HOSTNAME := `hostname -s`

default:
    @just --list --unsorted

ping host="":
    cd {{ ANSIBLE_DIR }} && ansible {{ if host == "" { "all" } else { quote(host) } }} -i {{ SSH_INVENTORY }} {{ if host == "" { "" } else { "-i " + host + "," } }} -m ansible.builtin.ping

local playbook tags="":
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ LOCAL_INVENTORY }} playbooks/{{ playbook }}.yml --limit {{ quote(HOSTNAME) }} -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}

ssh playbook host="" tags="":
    cd {{ ANSIBLE_DIR }} && ansible-playbook -i {{ SSH_INVENTORY }} {{ if host == "" { "" } else { "-i " + host + ", --limit " + quote(host) } }} playbooks/{{ playbook }}.yml -v {{ if tags == "" { "" } else { "--tags " + quote(tags) } }}
