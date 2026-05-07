#!/usr/bin/env bash
# pi-sync - sync pi skills and prompts across machines via git
# usage:
#   pi-sync init <remote-url>  - initialize repo and push
#   pi-sync clone <remote-url> - clone existing repo and link
#   pi-sync [sync]             - commit, pull, push (default)
#   pi-sync push               - commit and push local changes
#   pi-sync pull               - pull remote changes
#   pi-sync status             - show sync status

set -euo pipefail

PI_DIR="${PI_DIR:-$HOME/.pi/agent}"
REPO_DIR="${PI_SYNC_REPO:-$HOME/.pi/sync}"

# repo-path:local-path
DIRS=(
    "skills:$PI_DIR/skills"
    "prompts:$PI_DIR/prompts"
)

usage() {
    echo "Usage:"
    echo "  pi-sync init <remote-url>  - initialize repo and push"
    echo "  pi-sync clone <remote-url> - clone existing repo and link"
    echo "  pi-sync [sync]             - commit, pull, push (default)"
    echo "  pi-sync push               - commit and push local changes"
    echo "  pi-sync pull               - pull remote changes"
    echo "  pi-sync status             - show sync status"
    exit 1
}

# Ensure local paths are symlinks into the repo
link() {
    for mapping in "${DIRS[@]}"; do
        local repo_path="${mapping%%:*}"
        local local_path="${mapping##*:}"
        local target="$REPO_DIR/$repo_path"

        mkdir -p "$target"

        if [[ -L "$local_path" ]]; then
            continue
        elif [[ -d "$local_path" ]]; then
            # Migrate existing dir contents into repo, then replace with symlink
            rsync -a "$local_path/" "$target/"
            rm -rf "$local_path"
        fi

        mkdir -p "$(dirname "$local_path")"
        ln -s "$target" "$local_path"
        echo "Linked: $local_path -> $target"
    done
}

auto_commit() {
    cd "$REPO_DIR"
    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "Update: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Committed changes."
    else
        echo "No changes to commit."
    fi
}

cmd_init() {
    local url="${1:?Error: init requires <remote-url>}"
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR"
    git init -b master
    git remote add origin "$url"
    link
    git add -A
    git commit -m "Initial commit" || echo "Nothing to commit."
    git push -u origin master
    echo "Initialized and pushed to $url"
}

cmd_clone() {
    local url="${1:?Error: clone requires <remote-url>}"
    if [[ -d "$REPO_DIR" ]]; then
        echo "Error: $REPO_DIR already exists. Remove it first."
        exit 1
    fi
    git clone "$url" "$REPO_DIR"
    link
    echo "Cloned and linked."
}

cmd_push() {
    cd "$REPO_DIR"
    auto_commit
    git push
    echo "Pushed."
}

cmd_pull() {
    cd "$REPO_DIR"
    auto_commit
    git pull --rebase || {
        echo "Error: rebase conflict. Resolve in $REPO_DIR"
        git rebase --abort 2>/dev/null
        exit 1
    }
    echo "Pulled."
}

cmd_sync() {
    cd "$REPO_DIR"
    auto_commit
    git pull --rebase || {
        echo "Error: rebase conflict. Resolve in $REPO_DIR"
        git rebase --abort 2>/dev/null
        exit 1
    }
    git push
    echo "Synced."
}

cmd_status() {
    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "Not initialized. Run: pi-sync init <url>"
        exit 1
    fi
    echo "Repo: $REPO_DIR"
    echo "Links:"
    for mapping in "${DIRS[@]}"; do
        local repo_path="${mapping%%:*}"
        local local_path="${mapping##*:}"
        if [[ -L "$local_path" ]]; then
            echo "  $local_path -> $(readlink "$local_path") ✓"
        elif [[ -d "$local_path" ]]; then
            echo "  $local_path (not linked, run init or clone)"
        else
            echo "  $local_path (missing)"
        fi
    done
    echo ""
    cd "$REPO_DIR"
    git status --short
}

cmd="${1:-sync}"
shift 2>/dev/null || true

case "$cmd" in
    init)   cmd_init "$@" ;;
    clone)  cmd_clone "$@" ;;
    push)   cmd_push ;;
    pull)   cmd_pull ;;
    sync)   cmd_sync ;;
    status) cmd_status ;;
    -h|--help) usage ;;
    *)      echo "Error: unknown command '$cmd'"; usage ;;
esac
