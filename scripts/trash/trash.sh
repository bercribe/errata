# trash - move files to trash instead of deleting
if [[ "$(uname)" == 'Darwin' ]]; then
  for arg in "$@"; do
    file="$(realpath "$arg")"
    /usr/bin/osascript -e "tell application \"Finder\" to delete POSIX file \"$file\"" > /dev/null
  done
else
  gio trash "$@"
fi
