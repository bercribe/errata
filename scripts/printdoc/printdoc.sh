if [[ $# -ne 1 ]]; then
  echo "Usage: printdoc <file>" >&2
  exit 1
fi

file="$1"

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

echo "Printing '$file'..."
lp -n 1 -o sides=two-sided-long-edge -- "$file"
