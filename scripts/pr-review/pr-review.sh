# pr-review.sh - review a github PR locally in a git worktree + nvim/octo
#
# usage:
#   pr-review <pr-number|pr-url>   open (or resume) a review
#   pr-review --clean <number>     remove the worktree for one PR
#   pr-review --clean-all          remove all worktrees for the current repo

set -euo pipefail

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/pr-review"

usage() {
    echo "Usage: pr-review <pr-number|pr-url>"
    echo "       pr-review --clean <number>"
    echo "       pr-review --clean-all"
    exit 1
}

# turns a git remote url (ssh or https) into an "owner-repo" slug
repo_slug() {
    local url
    url=$(git remote get-url origin)
    if [[ ! $url =~ http ]]; then # assume ssh form
        url=$(echo "$url" | sed -E 's|.*git@(.*):|https://\1/|')
    fi
    url=${url%.git}
    echo "$url" | sed -E 's#.*/([^/]+/[^/]+)$#\1#' | tr '/' '-'
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

worktree_dir_for() {
    echo "$cache_root/$(repo_slug)/$1"
}

remove_worktree() {
    local dir=$1
    [[ -d $dir ]] || return 0
    git worktree remove --force "$dir" 2>/dev/null || rm -rf "$dir"
    git worktree prune
}

clean_one() {
    remove_worktree "$(worktree_dir_for "$1")"
}

clean_all() {
    local repo_dir
    repo_dir="$cache_root/$(repo_slug)"
    [[ -d $repo_dir ]] || return 0
    for dir in "$repo_dir"/*/; do
        [[ -d $dir ]] || continue
        remove_worktree "${dir%/}"
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
dir=$(worktree_dir_for "$number")

if [[ ! -d $dir ]]; then
    mkdir -p "$(dirname "$dir")"
    git worktree add "$dir" HEAD
fi

# `gh pr checkout` sets up the branch/tracking metadata that both `gh pr
# view` and Octo's current-branch PR detection rely on, so run it inside the
# worktree rather than manually fetching+checking out the PR ref ourselves.
(cd "$dir" && gh pr checkout "$number")

cd "$dir"
exec nvim +"Octo pr edit $number" +"Octo review"
