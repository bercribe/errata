# pr-review.sh - review a github PR locally in a git worktree + nvim
#
# usage:
#   pr-review <pr-number|pr-url>   open (or resume) a review
#   pr-review --clean <number>     remove everything for one PR
#   pr-review --clean-all          remove everything for the current repo

set -euo pipefail

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/pr-review"

usage() {
    echo "Usage: pr-review <pr-number|pr-url>"
    echo "       pr-review --clean <number>"
    echo "       pr-review --clean-all"
    exit 1
}

# parses a git remote url (ssh or https) into "owner repo"
owner_repo() {
    local url
    url=$(git remote get-url origin)
    if [[ ! $url =~ http ]]; then # assume ssh form
        url=$(echo "$url" | sed -E 's|.*git@(.*):|https://\1/|')
    fi
    url=${url%.git}
    echo "$url" | sed -E 's#.*/([^/]+)/([^/]+)$#\1 \2#'
}

repo_slug() {
    read -r owner repo <<<"$(owner_repo)"
    echo "${owner}-${repo}"
}

pr_number_from_arg() {
    local arg=$1
    if [[ $arg =~ ^[0-9]+$ ]]; then
        echo "$arg"
    elif [[ $arg =~ /pull/([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "Not a PR number or URL: $arg" >&2
        exit 1
    fi
}

session_dir_for() {
    echo "$cache_root/$(repo_slug)/$1"
}

remove_session() {
    local session_dir=$1
    [[ -d $session_dir ]] || return 0
    if [[ -d "$session_dir/worktree" ]]; then
        git worktree remove --force "$session_dir/worktree" 2>/dev/null || true
        git worktree prune
    fi
    rm -rf "$session_dir"
}

clean_one() {
    remove_session "$(session_dir_for "$1")"
}

clean_all() {
    local repo_dir
    repo_dir="$cache_root/$(repo_slug)"
    [[ -d $repo_dir ]] || return 0
    for dir in "$repo_dir"/*/; do
        [[ -d $dir ]] || continue
        remove_session "${dir%/}"
    done
    rmdir --ignore-fail-on-non-empty "$repo_dir" 2>/dev/null || true
}

[[ $# -ge 1 ]] || usage

case "$1" in
    --clean)
        [[ -n ${2:-} ]] || usage
        clean_one "$2"
        exit 0
        ;;
    --clean-all)
        clean_all
        exit 0
        ;;
    -h | --help)
        usage
        ;;
esac

number=$(pr_number_from_arg "$1")
read -r owner repo <<<"$(owner_repo)"
session_dir=$(session_dir_for "$number")
worktree_dir="$session_dir/worktree"

if [[ ! -d $worktree_dir ]]; then
    mkdir -p "$session_dir"
    git worktree add "$worktree_dir" HEAD
fi

# `gh pr checkout` sets up the branch/tracking metadata gh itself needs for
# forked PRs, so run it inside the worktree rather than fetching manually.
(cd "$worktree_dir" && gh pr checkout "$number")

export PR_REVIEW_DIR="$session_dir"
export PR_REVIEW_NUMBER="$number"
export PR_REVIEW_OWNER="$owner"
export PR_REVIEW_REPO="$repo"

cd "$worktree_dir"
exec nvim
