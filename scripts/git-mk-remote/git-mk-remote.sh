#!/usr/bin/env bash
# Set up a git remote over ssh and push
# usage: git-mk-remote <host> <remote-path> [branch]
# example: git-mk-remote super-fly sources/nixos

set -euo pipefail

host="${1:?Usage: git-push-ssh <host> <remote-path> [branch]}"
remote_path="${2:?Usage: git-push-ssh <host> <remote-path> [branch]}"
branch="${3:-$(git rev-parse --abbrev-ref HEAD)}"

ssh_target="${host}-git"
remote_home=$(ssh "$ssh_target" 'echo $HOME')
remote_url="ssh://${ssh_target}/${remote_home}/${remote_path}"

if ! git remote get-url "$host" &>/dev/null; then
  git remote add "$host" "$remote_url"
  echo "Added remote: $host -> $remote_url"
fi

git push "$host" "$branch"
