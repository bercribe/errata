if [[ $# -ne 1 ]]; then
  echo "Usage: printdoc <file>" >&2
  exit 1
fi

file="$1"
PRINTDOC_LUA_FILTER="${PRINTDOC_LUA_FILTER:-$(dirname "$0")/strip-codeblocks.lua}"

if [[ ! -f "$file" ]]; then
  echo "Error: file not found: $file" >&2
  exit 1
fi

# If no default printer, prompt to pick one
if [[ -z "$(lpstat -d 2>/dev/null | sed -n 's/^system default destination: //p')" ]]; then
  mapfile -t printers < <(lpstat -a 2>/dev/null | awk '{print $1}')

  if [[ ${#printers[@]} -eq 0 ]]; then
    echo "Error: no printers found." >&2
    exit 1
  fi

  echo "No default printer set."
  printer=$(printf '%s\n' "${printers[@]}" | fzf --prompt="Select printer: ")

  if [[ -z "$printer" ]]; then
    echo "No printer selected." >&2
    exit 1
  fi

  lpoptions -d "$printer"
  echo "Default printer set to: $printer"
fi

# Render markdown to PDF if needed
print_file="$file"
if [[ "$file" == *.md ]]; then
  print_file=$(mktemp --suffix=.pdf)
  trap 'rm -f "$print_file"' EXIT
  echo "Rendering markdown to PDF..."
  pandoc "$file" --lua-filter="$PRINTDOC_LUA_FILTER" -o "$print_file"
fi

echo "Printing '$file'..."
lp -n 1 -o sides=two-sided-long-edge -- "$print_file"
