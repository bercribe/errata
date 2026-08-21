#!/usr/bin/env bash
# Set up a git remote over ssh and push
# usage: git-mk-remote <host> <remote-path> [branch]
# example: git-mk-remote super-fly sources/nixos

set -euo pipefail

host="${1:?Usage: git-push-ssh <host> <remote-path> [branch]}"
remote_path="${2:?Usage: git-push-ssh <host> <remote-path> [branch]}"
branch="${3:-$(git rev-parse --abbrev-ref HEAD)}"

remote_name="${host}-git"
remote_home=$(ssh "$remote_name" 'echo $HOME')
remote_url="ssh://${remote_name}/${remote_home}/${remote_path}"

if ! git remote get-url "$remote_name" &>/dev/null; then
  git remote add "$remote_name" "$remote_url"
  echo "Added remote: $remote_name -> $remote_url"
fi

git push "$remote_name" "$branch"
