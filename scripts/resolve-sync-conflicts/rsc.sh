#!/usr/bin/env bash
# rsc.sh: resolve syncthing conflicts
# Usage: rsc.sh <directory>

set -euo pipefail

DIR="${1:-}"

usage() {
  echo "Usage: rsc.sh <directory>"
  echo ""
  echo "Interactive tool to resolve syncthing version conflicts."
  echo "Finds all .sync-conflict-* files and lets you resolve them via fzf."
  echo ""
  echo "Keybindings:"
  echo "  enter   - view diff (delta)"
  echo "  ctrl-o  - keep original (delete conflict file)"
  echo "  ctrl-c  - keep conflict (replace original with conflict)"
  echo "  ctrl-e  - edit manually (vimdiff)"
  exit 0
}

case "${1:-}" in
  --help|-h) usage ;;
esac

if [[ -z "$DIR" ]]; then usage; fi
if [[ ! -d "$DIR" ]]; then echo "Error: '$DIR' is not a directory." >&2; exit 1; fi
for cmd in fzf delta; do
  if ! command -v "$cmd" &>/dev/null; then echo "Error: $cmd is required." >&2; exit 1; fi
done

ABS_DIR="$(realpath "$DIR")"

find_conflicts() {
  find "$ABS_DIR" -type f -name '*.sync-conflict*' -not -path '*/.stversions/*' | sort
}

# Given a conflict file, derive the original file path.
# e.g. foo.sync-conflict-20240101-120000-ABCDEFG.txt -> foo.txt
get_original() {
  local conflict="$1"
  local base ext
  # Remove .sync-conflict-<date>-<time>-<id> portion
  base="${conflict%.sync-conflict*}"
  local after="${conflict#*".sync-conflict-"}"
  # after is like "20240101-120000-ABCDEFG.txt"
  ext=".${after#*.}"
  echo "${base}${ext}"
}

preview_diff() {
  local conflict="$1"
  local original
  original=$(get_original "$conflict")
  if [[ -f "$original" ]]; then
    delta --paging=always "$original" "$conflict" 2>&1 || true
  else
    echo "Original file not found: $original"
    echo ""
    bat --paging=always "$conflict" 2>/dev/null || cat "$conflict"
  fi
}

keep_original() {
  local conflict="$1"
  rm "$conflict" && echo "Deleted conflict file: $conflict"
}

keep_conflict() {
  local conflict="$1"
  local original
  original=$(get_original "$conflict")
  mv "$conflict" "$original" && echo "Replaced original with conflict: $original"
}

edit_manual() {
  local conflict="$1"
  local original
  original=$(get_original "$conflict")
  if [[ -f "$original" ]]; then
    nvim -d "$original" "$conflict"
  else
    nvim "$conflict"
  fi
}

# Auto-delete duplicate conflicts for the same original file.
# Groups conflicts by original, and within each group removes files
# that are byte-identical to an earlier one in the group.
auto_prune() {
  local pruned=0
  declare -A seen_groups  # original -> list of kept conflict files (newline-separated)

  while IFS= read -r conflict; do
    local original
    original=$(get_original "$conflict")
    local dominated=false

    if [[ -n "${seen_groups[$original]+x}" ]]; then
      while IFS= read -r kept; do
        [[ -z "$kept" ]] && continue
        if cmp -s "$conflict" "$kept"; then
          rm "$conflict"
          echo "  Pruned (duplicate): $conflict"
          ((pruned+=1))
          dominated=true
          break
        fi
      done <<< "${seen_groups[$original]}"
    fi

    if [[ "$dominated" == false ]]; then
      seen_groups[$original]+="$conflict"$'\n'
    fi
  done < <(find_conflicts)

  if [[ $pruned -gt 0 ]]; then
    echo "Auto-deleted $pruned duplicate conflict(s)."
    echo ""
  fi
}

auto_prune

export -f find_conflicts get_original preview_diff keep_original keep_conflict edit_manual
export ABS_DIR

mapfile -t conflicts < <(find_conflicts)

if [[ ${#conflicts[@]} -eq 0 ]]; then
  echo "No sync conflicts found in $ABS_DIR"
  exit 0
fi

echo "Found ${#conflicts[@]} remaining conflict file(s)."

printf '%s\n' "${conflicts[@]}" | fzf \
  --prompt="conflict > " \
  --header="enter: view diff | ctrl-o: keep original | ctrl-k: keep conflict | ctrl-e: vimdiff" \
  --preview="bash -c 'preview_diff {}'" \
  --preview-window="right:60%:wrap" \
  --bind "enter:execute(bash -c 'preview_diff {}')" \
  --bind "ctrl-o:execute(
    echo 'Keep original and delete {}? [y/N]';
    read ans;
    if [[ \$ans == y || \$ans == Y ]]; then
      bash -c 'keep_original {}' && echo 'Done.';
    fi
  )+reload(bash -c 'find_conflicts {}')" \
  --bind "ctrl-k:execute(
    echo 'Replace original with {}? [y/N]';
    read ans;
    if [[ \$ans == y || \$ans == Y ]]; then
      bash -c 'keep_conflict {}' && echo 'Done.';
    fi
  )+reload(bash -c 'find_conflicts {}')" \
  --bind "ctrl-e:execute(bash -c 'edit_manual {}')+reload(bash -c 'find_conflicts {}')" \
  || true
