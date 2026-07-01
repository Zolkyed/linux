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
  echo "Usage: $0 [encrypt|decrypt]" >&2
}

select_action() {
  local choice

  cat >&2 <<'EOF'
Select an operation:
  1) Encrypt vault files
  2) Decrypt vault files
  0) Exit
EOF

  while true; do
    if ! read -r -p "Selection [0-2]: " choice; then
      echo "ERROR: unable to read operation selection." >&2
      return 1
    fi
    case "$choice" in
      1) printf '%s' encrypt; return ;;
      2) printf '%s' decrypt; return ;;
      0) return 1 ;;
      *) echo "ERROR: select a number from 0 to 2." >&2 ;;
    esac
  done
}

if (( $# == 0 )); then
  [[ -t 0 && -t 1 ]] || { echo "ERROR: interactive mode requires a terminal." >&2; exit 1; }
  ACTION="$(select_action)" || { echo "==> No operation selected."; exit 0; }
elif (( $# == 1 )) && [[ "$1" =~ ^(encrypt|decrypt)$ ]]; then
  ACTION="$1"
else
  usage
  exit 1
fi
readonly ACTION

mapfile -t VAULT_FILES < <(
  cd "$REPO_ROOT"
  find ansible/inventory -type f -name vault.yml | sort
)

[[ "${#VAULT_FILES[@]}" -gt 0 ]] || {
  echo "No vault files found under ansible/inventory" >&2
  exit 1
}

is_encrypted() {
  sops filestatus "$1" 2>/dev/null | grep -Eq '"encrypted"[[:space:]]*:[[:space:]]*true'
}

for rel_path in "${VAULT_FILES[@]}"; do
  file="${REPO_ROOT}/${rel_path}"

  if [[ "$ACTION" == "encrypt" ]]; then
    is_encrypted "$file" && { echo "Already encrypted: ${rel_path}"; continue; }
    sops --encrypt --in-place "$file"
    echo "Encrypted: ${rel_path}"
  else
    is_encrypted "$file" || { echo "Already decrypted: ${rel_path}"; continue; }
    sops --decrypt --in-place "$file"
    echo "Decrypted: ${rel_path}"
  fi
done
