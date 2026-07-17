#!/usr/bin/env bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANSIBLE_DIR="${REPO_DIR}/ansible"
AGE_KEY_ENCRYPTED="${REPO_DIR}/secrets/age_key.age"
SUDOERS_FILE="/etc/sudoers.d/99-nopasswd"
PACKAGES=(age sops ansible just)
VALID_HOSTS=(desktop laptop)

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

banner() {
    [[ -t 1 ]] && clear
    cat <<'BANNER'
  █████╗ ███╗   ██╗███████╗██╗██████╗ ██╗     ███████╗
 ██╔══██╗████╗  ██║██╔════╝██║██╔══██╗██║     ██╔════╝
 ███████║██╔██╗ ██║███████╗██║██████╔╝██║     █████╗
 ██╔══██║██║╚██╗██║╚════██║██║██╔══██╗██║     ██╔══╝
 ██║  ██║██║ ╚████║███████║██║██████╔╝███████╗███████╗
 ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝
BANNER
}

resolve_target() {
    local host="${TARGET_HOST:-${1:-$(hostname -s)}}"
    local valid
    for valid in "${VALID_HOSTS[@]}"; do
        [[ "$host" == "$valid" ]] && { printf '%s' "$host"; return; }
    done
    echo "ERROR: unknown host '${host}' — expected one of: ${VALID_HOSTS[*]}" >&2
    exit 1
}

setup_sudo() {
    local user="${USER}"
    local tmp; tmp="$(mktemp)"
    printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$user" >"$tmp"
    visudo -cf "$tmp" >/dev/null
    sudo install -o root -g root -m 0440 "$tmp" "$SUDOERS_FILE"
    rm -f "$tmp"
    echo "==> Passwordless sudo granted to ${user}"
}

decrypt_age_key() {
    [[ -f "$SOPS_AGE_KEY_FILE" ]] && return
    [[ -f "$AGE_KEY_ENCRYPTED" ]] || {
        echo "ERROR: no age key at ${SOPS_AGE_KEY_FILE} and no encrypted key at ${AGE_KEY_ENCRYPTED}" >&2
        exit 1
    }
    mkdir -p "$(dirname "$SOPS_AGE_KEY_FILE")"
    if ! age -d -o "$SOPS_AGE_KEY_FILE" "$AGE_KEY_ENCRYPTED" 2>/dev/null; then
        rm -f "$SOPS_AGE_KEY_FILE"
        echo "ERROR: failed to decrypt age key — wrong passphrase?" >&2
        exit 1
    fi
    chmod 600 "$SOPS_AGE_KEY_FILE"
    echo "==> Age key decrypted"
}

# Main
main() {
    banner

    [[ "${EUID}" -eq 0 ]] && { echo "ERROR: run as the installed user, not root." >&2; exit 1; }

    local target_host; target_host="$(resolve_target "$@")"

    setup_sudo

    echo "==> Upgrading system..."
    sudo pacman -Syu --noconfirm

    echo "==> Installing dependencies..."
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

    decrypt_age_key

    echo "==> Installing Ansible collections..."
    ansible-galaxy collection install -r "${ANSIBLE_DIR}/requirements.yml"

    echo "==> Running playbook..."
    cd "$ANSIBLE_DIR"
    ansible-playbook -i inventory/local.yml playbooks/setup.yml -l "$target_host"
    echo "==> Done."
}

main "$@"
