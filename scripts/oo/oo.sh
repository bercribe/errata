vault_dir=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/oo/vault")

file=$(realpath "$1")
if [[ ! "$file" == "$vault_dir"/* ]]; then
  echo "error: file is not inside vault: $file" >&2
  exit 1
fi

relative="${file#"$vault_dir"/}"
encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$relative")
vault_name=$(basename "$vault_dir")
vault_encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$vault_name")

xdg-open "obsidian://open?vault=${vault_encoded}&file=${encoded}"
