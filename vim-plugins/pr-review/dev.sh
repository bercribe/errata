#!/usr/bin/env bash
# usage: run the real `pr-review <pr-number>` once first to set up the
# worktree/session, then from here on use:
#   ./dev.sh <pr-number>

set -euo pipefail

plugin_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/pr-review"

owner_repo() {
    local url
    url=$(git remote get-url origin)
    if [[ ! $url =~ http ]]; then
        url=$(echo "$url" | sed -E 's|.*git@(.*):|https://\1/|')
    fi
    url=${url%.git}
    echo "$url" | sed -E 's#.*/([^/]+)/([^/]+)$#\1 \2#'
}

[[ $# -ge 1 ]] || {
    echo "Usage: $0 <pr-number>" >&2
    exit 1
}
number=$1

read -r owner repo <<<"$(owner_repo)"
session_dir="$cache_root/${owner}-${repo}/$number"
worktree_dir="$session_dir/worktree"

if [[ ! -d $worktree_dir ]]; then
    echo "No existing session for PR $number ($session_dir)." >&2
    echo "Run the real 'pr-review $number' once first to set it up." >&2
    exit 1
fi

export PR_REVIEW_DIR="$session_dir"
export PR_REVIEW_NUMBER="$number"
export PR_REVIEW_OWNER="$owner"
export PR_REVIEW_REPO="$repo"

cd "$worktree_dir"
exec nvim --cmd "set rtp^=$plugin_dir"
