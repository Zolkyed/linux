#!/usr/bin/env bash
set -euo pipefail

[[ -t 1 ]] && clear

cat <<'BANNER'
 ██╗   ██╗ █████╗ ██╗   ██╗██╗     ████████╗
 ██║   ██║██╔══██╗██║   ██║██║     ╚══██╔══╝
 ██║   ██║███████║██║   ██║██║        ██║
 ╚██╗ ██╔╝██╔══██║██║   ██║██║        ██║
  ╚████╔╝ ██║  ██║╚██████╔╝███████╗   ██║
   ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝
BANNER

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "Usage: $0 [SOPS_FILE]" >&2
}

select_file() {
  local choice

  echo "Select a SOPS file to edit:" >&2
  local index
  for index in "${!VAULT_FILES[@]}"; do
    printf '  %d) %s\n' "$((index + 1))" "${VAULT_FILES[$index]}" >&2
  done
  echo "  0) Exit" >&2

  while true; do
    if ! read -r -p "Selection [0-${#VAULT_FILES[@]}]: " choice; then
      echo "ERROR: unable to read file selection." >&2
      return 1
    fi
    [[ "$choice" == 0 ]] && return 1
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#VAULT_FILES[@]} )); then
      printf '%s' "${VAULT_FILES[$((choice - 1))]}"
      return
    fi
    echo "ERROR: select a number from 0 to ${#VAULT_FILES[@]}." >&2
  done
}

mapfile -t VAULT_FILES < <(
  cd "$REPO_ROOT"
  find ansible/inventory -type f -name '*.sops.yml' | sort
)

[[ "${#VAULT_FILES[@]}" -gt 0 ]] || {
  echo "No vault files found under ansible/inventory" >&2
  exit 1
}

if (( $# == 0 )); then
  [[ -t 0 && -t 1 ]] || { echo "ERROR: interactive mode requires a terminal." >&2; exit 1; }
  REL_PATH="$(select_file)" || { echo "==> No file selected."; exit 0; }
elif (( $# == 1 )); then
  REL_PATH="${1#"${REPO_ROOT}/"}"
  [[ " ${VAULT_FILES[*]} " == *" ${REL_PATH} "* ]] || {
    echo "ERROR: '${1}' is not a SOPS file under ansible/inventory." >&2
    usage
    exit 1
  }
else
  usage
  exit 1
fi

sops "${REPO_ROOT}/${REL_PATH}"
