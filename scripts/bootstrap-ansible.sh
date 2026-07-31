#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_DIR="${REPO_DIR}/ansible"
readonly REPO_DIR ANSIBLE_DIR
readonly -a PACKAGES=(age sops ansible just)

SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
readonly SOPS_AGE_KEY_FILE

TEMPORARY_PATHS=()

cleanup() {
    local path
    for path in "${TEMPORARY_PATHS[@]}"; do
        [[ ! -e "$path" ]] || rm -rf -- "$path"
    done
}

trap cleanup EXIT

die() {
    echo "ERROR: $*" >&2
    exit 1
}

install_packages() {
    echo "==> Upgrading Arch Linux packages"
    sudo pacman -Syu --noconfirm

    echo "==> Installing Arch Linux packages"
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
}

configure_passwordless_sudo() {
    local sudoers_file temporary user

    user="$(id -un)"
    sudoers_file="/etc/sudoers.d/99-ansible-${user}"
    temporary="$(mktemp)"
    TEMPORARY_PATHS+=("$temporary")

    printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$user" >"$temporary"
    visudo -cf "$temporary" >/dev/null
    sudo install -o root -g root -m 0440 "$temporary" "$sudoers_file"

    echo "==> Passwordless sudo configured for ${user}"
}

install_age_identity() {
    [[ -f "$SOPS_AGE_KEY_FILE" ]] || \
        die "age identity missing at ${SOPS_AGE_KEY_FILE} — copy it from your password manager first"

    chmod 600 "$SOPS_AGE_KEY_FILE"
    grep -q '^AGE-SECRET-KEY-' "$SOPS_AGE_KEY_FILE" || \
        die "existing file is not an age identity: ${SOPS_AGE_KEY_FILE}"
    echo "==> Existing age identity retained at ${SOPS_AGE_KEY_FILE}"
}

install_collections() {
    echo "==> Installing Ansible collections"
    ansible-galaxy collection install \
        --requirements-file "${ANSIBLE_DIR}/requirements.yml"
}

main() {
    [[ "${EUID}" -ne 0 ]] || die "run this script as the installed user, not root"

    install_packages
    configure_passwordless_sudo
    install_age_identity
    install_collections

    echo "==> Ansible bootstrap complete"
}

main "$@"
