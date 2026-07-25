# Create .Trash-<uid> directory at the mount point of the given path (or cwd)
target="${1:-.}"
mountpoint=$(df --output=target "$target" | tail -1)
trashdir="$mountpoint/.Trash-$(id -u)"

if [[ -d "$trashdir" ]]; then
    echo "Already exists: $trashdir"
elif mkdir "$trashdir" 2>/dev/null; then
    mkdir "$trashdir/files" "$trashdir/info"
    echo "Created: $trashdir"
else
    sudo mkdir "$trashdir"
    sudo chown "$(id -u):$(id -g)" "$trashdir"
    echo "Created (via sudo): $trashdir"
fi
