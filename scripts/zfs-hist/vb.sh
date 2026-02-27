#!/usr/bin/env bash
# vb.sh: ZFS version browser
# Usage: vb.sh <file> [-n <count>]

set -euo pipefail

FILE="${1:-}"
LIMIT=10

usage() {
  echo "Usage: vb.sh <file> [-n <count>]"
  exit 0
}

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n)        LIMIT="${2:-10}"; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$FILE" ]]; then usage; fi
if [[ ! -f "$FILE" ]]; then echo "Error: '$FILE' not found." >&2; exit 1; fi
if ! command -v fzf &>/dev/null; then echo "Error: fzf is required." >&2; exit 1; fi

ABS_FILE="$(realpath "$FILE")"
DATASET_MOUNT=$(df --output=target "$ABS_FILE" | tail -1)
RELATIVE_PATH="${ABS_FILE#"$DATASET_MOUNT/"}"
SNAP_DIR="$DATASET_MOUNT/.zfs/snapshot"

if [[ ! -d "$SNAP_DIR" ]]; then
  echo "Error: No ZFS snapshot directory found at $SNAP_DIR" >&2
  exit 1
fi

get_snaps() {
  local limit="${1:-$LIMIT}"
  local last_hash
  last_hash=$(md5sum "$ABS_FILE" | cut -d' ' -f1)
  for snap in "$SNAP_DIR"/*/; do
    [[ -f "$snap/$RELATIVE_PATH" ]] && basename "$snap"
  done | sort -r | while IFS= read -r snap_name; do
    local snap_file="$SNAP_DIR/$snap_name/$RELATIVE_PATH"
    local hash
    hash=$(md5sum "$snap_file" | cut -d' ' -f1)
    if [[ "$hash" != "$last_hash" ]]; then
      echo "$snap_name"
      last_hash="$hash"
    fi
  done | head -n "$limit"
}

preview_snap() {
  local snap_name="$1"
  local snap_file="$SNAP_DIR/$snap_name/$RELATIVE_PATH"
  bat --paging=always "$snap_file" || true
}
preview_diff() {
  local snap_name="$1"
  local snap_file="$SNAP_DIR/$snap_name/$RELATIVE_PATH"
  delta --paging=always "$snap_file" "$ABS_FILE" || true
}
restore_file() {
  local snap_name="$1"
  local snap_file="$SNAP_DIR/$snap_name/$RELATIVE_PATH"
  cp "$snap_file" "$ABS_FILE" || true
}

export -f preview_snap preview_diff restore_file
export ABS_FILE SNAP_DIR RELATIVE_PATH LIMIT

mapfile -t entries < <(get_snaps)

printf '%s\n' "${entries[@]}" | fzf \
  --prompt="snapshot > " \
  --header="enter: cat snapshot | ctrl-d: view diff | ctrl-r: restore" \
  --preview="bash -c 'preview_diff {}'" \
  --preview-window="right:60%:wrap" \
  --bind "enter:execute(bash -c 'preview_snap {}')" \
  --bind "ctrl-d:execute(bash -c 'preview_diff {}')" \
  --bind "ctrl-r:execute(
    echo 'Restore {} to $ABS_FILE? [y/N]';
    read ans;
    if [[ \$ans == y || \$ans == Y ]]; then
      bash -c 'restore_file {}' && echo 'Restored.'
    fi
  )" \
  || true
