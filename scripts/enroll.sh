#!/usr/bin/env bash
set -euo pipefail

readonly -a FINGERS=(
    left-thumb
    left-index-finger
    left-middle-finger
    left-ring-finger
    left-little-finger
    right-thumb
    right-index-finger
    right-middle-finger
    right-ring-finger
    right-little-finger
)

banner() {
    [[ -t 1 ]] || return
    clear
    cat <<'BANNER'
███████╗███╗   ██╗██████╗  ██████╗ ██╗     ██╗
██╔════╝████╗  ██║██╔══██╗██╔═══██╗██║     ██║
█████╗  ██╔██╗ ██║██████╔╝██║   ██║██║     ██║
██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║██║     ██║
███████╗██║ ╚████║██║  ██║╚██████╔╝███████╗███████╗
╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
BANNER
}

usage() {
    cat >&2 <<EOF
Usage:
  $0
  $0 fingerprint-enroll [finger]
  $0 fingerprint-list
  $0 fingerprint-delete
  $0 yubikey-enroll
  $0 yubikey-add
  $0 yubikey-delete
EOF
}

select_operation() {
    local choice

    cat >&2 <<'EOF'
Select an operation:
  1) Enroll a fingerprint
  2) List fingerprints
  3) Delete fingerprints
  4) Enroll a YubiKey
  5) Add another YubiKey
  6) Delete YubiKey registrations
  0) Exit
EOF

    while true; do
        if ! read -r -p "Selection [0-6]: " choice; then
            echo "ERROR: unable to read operation selection." >&2
            return 1
        fi
        case "$choice" in
            1) printf '%s' fingerprint-enroll; return ;;
            2) printf '%s' fingerprint-list; return ;;
            3) printf '%s' fingerprint-delete; return ;;
            4) printf '%s' yubikey-enroll; return ;;
            5) printf '%s' yubikey-add; return ;;
            6) printf '%s' yubikey-delete; return ;;
            0) return 1 ;;
            *) echo "ERROR: select a number from 0 to 6." >&2 ;;
        esac
    done
}

require_command() {
    local command_name="$1"
    command -v "$command_name" >/dev/null 2>&1 || {
        echo "ERROR: required command '${command_name}' is not installed." >&2
        exit 1
    }
}

validate_arguments() {
    case "${1:-}" in
        fingerprint-enroll)
            [[ $# -le 2 ]] || { usage; exit 1; }
            ;;
        fingerprint-list|fingerprint-delete|yubikey-enroll|yubikey-add|yubikey-delete)
            [[ $# -eq 1 ]] || { usage; exit 1; }
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

validate_finger() {
    local valid_finger
    for valid_finger in "${FINGERS[@]}"; do
        [[ "$1" == "$valid_finger" ]] && return
    done

    echo "ERROR: invalid finger '${1}'." >&2
    exit 1
}

select_finger() {
    local choice
    local index

    echo "Select a finger to enroll:" >&2
    echo "  0) Automatic" >&2
    for index in "${!FINGERS[@]}"; do
        printf '  %d) %s\n' "$((index + 1))" "${FINGERS[$index]}" >&2
    done

    while true; do
        if ! read -r -p "Selection [0-${#FINGERS[@]}]: " choice; then
            echo "ERROR: unable to read finger selection." >&2
            exit 1
        fi
        case "$choice" in
            0)
                return
                ;;
            [1-9]|10)
                printf '%s' "${FINGERS[$((choice - 1))]}"
                return
                ;;
            *)
                echo "ERROR: select a number from 0 to ${#FINGERS[@]}." >&2
                ;;
        esac
    done
}

write_mapping() {
    local mapping_file="$1"
    local mapping="$2"
    local temporary_file

    temporary_file="$(mktemp)"
    if ! printf '%s\n' "$mapping" >"$temporary_file" \
        || ! chmod 0600 "$temporary_file" \
        || ! sudo install -o root -g root -m 0600 "$temporary_file" "$mapping_file"; then
        rm -f "$temporary_file"
        return 1
    fi
    rm -f "$temporary_file"
}

enroll_fingerprint() {
    require_command fprintd-enroll
    require_command fprintd-verify

    local enroll_user
    local finger="${1:-}"
    local -a enroll_args
    local -a verify_args
    enroll_user="$(id -un)"

    [[ -n "$finger" ]] || finger="$(select_finger)"
    enroll_args=("$enroll_user")
    verify_args=("$enroll_user")
    if [[ -n "$finger" ]]; then
        validate_finger "$finger"
        enroll_args=(-f "$finger" "$enroll_user")
        verify_args=(-f "$finger" "$enroll_user")
    fi

    echo "==> Scan the requested finger when prompted."
    fprintd-enroll "${enroll_args[@]}"

    echo "==> Verify the enrolled fingerprint."
    fprintd-verify "${verify_args[@]}"
}

list_fingerprints() {
    require_command fprintd-list

    fprintd-list "$(id -un)"
}

delete_fingerprints() {
    require_command fprintd-delete

    local enroll_user
    local response
    enroll_user="$(id -un)"

    read -r -p "Delete all fingerprints enrolled for ${enroll_user}? [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]] || {
        echo "==> Fingerprint deletion cancelled."
        return
    }

    fprintd-delete "$enroll_user"
    echo "==> Fingerprints deleted for ${enroll_user}."
}

enroll_yubikey() {
    require_command pamu2fcfg
    require_command sudo

    local mapping_file="/etc/security/u2f_mappings"
    local enroll_user
    local existing_mapping
    local existing_mappings=""
    local mapping
    local origin

    enroll_user="$(id -un)"
    origin="pam://$(hostname)"

    if sudo test -f "$mapping_file"; then
        existing_mappings="$(sudo cat "$mapping_file")"
    fi
    existing_mapping="$(awk -F: -v user="$enroll_user" '$1 == user { print; exit }' \
        <<<"$existing_mappings")"
    [[ -z "$existing_mapping" ]] || {
        echo "ERROR: ${mapping_file} already contains a registration for ${enroll_user}." >&2
        echo "Use '$0 yubikey-add' to register another key." >&2
        exit 1
    }

    echo "==> Touch the YubiKey when it starts flashing."
    mapping="$(pamu2fcfg -u "$enroll_user" -o "$origin" -i "$origin")"
    [[ "$mapping" == "${enroll_user}:"* ]] || {
        echo "ERROR: pamu2fcfg returned an invalid mapping." >&2
        exit 1
    }

    [[ -z "$existing_mappings" ]] || mapping="${existing_mappings}"$'\n'"${mapping}"
    write_mapping "$mapping_file" "$mapping"
    echo "==> Registration saved to ${mapping_file} (root:root, mode 0600)."
    echo "==> Registration is bound to ${origin}; re-enroll after a hostname change."
}

add_yubikey() {
    require_command pamu2fcfg
    require_command sudo

    local mapping_file="/etc/security/u2f_mappings"
    local enroll_user
    local existing_mapping
    local existing_mappings
    local additional_mapping
    local origin

    enroll_user="$(id -un)"
    origin="pam://$(hostname)"

    existing_mappings="$(sudo cat "$mapping_file" 2>/dev/null || true)"
    existing_mapping="$(awk -F: -v user="$enroll_user" '$1 == user { print; exit }' \
        <<<"$existing_mappings")"
    [[ -n "$existing_mapping" ]] || {
        echo "ERROR: no existing registration found for ${enroll_user} in ${mapping_file}." >&2
        echo "Use '$0 yubikey-enroll' to register the first key." >&2
        exit 1
    }

    echo "==> Touch the additional YubiKey when it starts flashing."
    additional_mapping="$(pamu2fcfg -n -o "$origin" -i "$origin")"
    [[ "$additional_mapping" == :* ]] || additional_mapping=":${additional_mapping}"

    existing_mappings="$(awk -F: -v user="$enroll_user" -v key="$additional_mapping" \
        '$1 == user { $0 = $0 key } { print }' <<<"$existing_mappings")"
    write_mapping "$mapping_file" "$existing_mappings"
    echo "==> Additional registration saved to ${mapping_file} (root:root, mode 0600)."
    echo "==> Registration is bound to ${origin}; re-enroll after a hostname change."
}

delete_yubikeys() {
    require_command sudo

    local mapping_file="/etc/security/u2f_mappings"
    local enroll_user
    local existing_mappings
    local response
    local updated_mappings

    enroll_user="$(id -un)"
    existing_mappings="$(sudo cat "$mapping_file" 2>/dev/null || true)"
    if ! awk -F: -v user="$enroll_user" '$1 == user { found = 1 } END { exit !found }' \
        <<<"$existing_mappings"; then
        echo "ERROR: no YubiKey registrations found for ${enroll_user}." >&2
        exit 1
    fi

    read -r -p "Delete all YubiKey registrations for ${enroll_user}? [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]] || {
        echo "==> YubiKey deletion cancelled."
        return
    }

    updated_mappings="$(awk -F: -v user="$enroll_user" '$1 != user' \
        <<<"$existing_mappings")"
    write_mapping "$mapping_file" "$updated_mappings"
    echo "==> YubiKey registrations deleted for ${enroll_user}."
    echo "==> Run '$0 yubikey-enroll' to enroll again."
}

# Main
main() {
    local operation

    (( $# == 0 )) || validate_arguments "$@"
    [[ "${EUID}" -ne 0 ]] || {
        echo "ERROR: run as the user being enrolled, not root." >&2
        exit 1
    }
    [[ -t 0 && -t 1 ]] || {
        echo "ERROR: enrollment requires an interactive terminal." >&2
        exit 1
    }

    banner

    if (( $# == 0 )); then
        operation="$(select_operation)" || {
            echo "==> No operation selected."
            return
        }
        set -- "$operation"
    fi

    case "$1" in
        fingerprint-enroll) enroll_fingerprint "${2:-}" ;;
        fingerprint-list) list_fingerprints ;;
        fingerprint-delete) delete_fingerprints ;;
        yubikey-enroll) enroll_yubikey ;;
        yubikey-add) add_yubikey ;;
        yubikey-delete) delete_yubikeys ;;
        *) usage; exit 1 ;;
    esac
}

main "$@"
