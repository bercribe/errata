# snippets - print a snippet from config
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
snippets_path="$XDG_CONFIG_HOME/snippets"

if [[ $# -ne 1 ]]; then
  ls "$snippets_path"
else
  if [[ "$1" == *".."* ]]; then
    echo 'invalid snippet name' 1>&2
    exit 1
  fi

  path="$snippets_path/$1"

  if ! cat "$path" 2>/dev/null; then
    echo "no snippet found at $path" 1>&2
    exit 1
  fi
fi
