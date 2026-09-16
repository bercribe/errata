#!/usr/bin/env bash
# Reattach an existing directory of files to its git history
# usage: git-resync <remote-url> [target-dir]
# example: git-resync git@host:you/repo.git ~/synced-folder

set -euo pipefail

remote_url="${1:?Usage: git-resync <remote-url> [target-dir]}"
target_dir="${2:-.}"

if [[ -e "${target_dir}/.git" ]]; then
  echo "Error: ${target_dir}/.git already exists" >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

git clone "$remote_url" "$tmp_dir"
mv "$tmp_dir/.git" "$target_dir/.git"

git -C "$target_dir" status
