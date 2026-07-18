#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_DIR="${REPO_DIR}/ansible"
ENCRYPTED_AGE_KEY="${REPO_DIR}/secrets/age_key.age"
readonly REPO_DIR ANSIBLE_DIR ENCRYPTED_AGE_KEY
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
    local identity_dir temporary

    if [[ -f "$SOPS_AGE_KEY_FILE" ]]; then
        chmod 600 "$SOPS_AGE_KEY_FILE"
        grep -q '^AGE-SECRET-KEY-' "$SOPS_AGE_KEY_FILE" || \
            die "existing file is not an age identity: ${SOPS_AGE_KEY_FILE}"
        echo "==> Existing age identity retained at ${SOPS_AGE_KEY_FILE}"
        return
    fi

    [[ -f "$ENCRYPTED_AGE_KEY" ]] || die "missing encrypted age identity: ${ENCRYPTED_AGE_KEY}"
    grep -q '^AGE-SECRET-KEY-' "$ENCRYPTED_AGE_KEY" && \
        die "${ENCRYPTED_AGE_KEY} contains a plaintext age identity"

    identity_dir="$(dirname "$SOPS_AGE_KEY_FILE")"
    install -d -m 0700 "$identity_dir"
    umask 077
    temporary="$(mktemp "${identity_dir}/keys.txt.XXXXXX")"
    TEMPORARY_PATHS+=("$temporary")

    if ! age --decrypt --output "$temporary" "$ENCRYPTED_AGE_KEY"; then
        die "failed to decrypt the age identity"
    fi

    grep -q '^AGE-SECRET-KEY-' "$temporary" || {
        die "decrypted file is not an age identity"
    }

    mv "$temporary" "$SOPS_AGE_KEY_FILE"
    echo "==> Age identity installed at ${SOPS_AGE_KEY_FILE}"
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
