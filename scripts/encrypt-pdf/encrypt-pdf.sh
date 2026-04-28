if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: encrypt-pdf <input.pdf> [output.pdf]" >&2
  exit 1
fi

input="$1"
output="${2:-${input%.pdf}-encrypted.pdf}"

if [[ ! -f "$input" ]]; then
  echo "Error: file not found: $input" >&2
  exit 1
fi

read -rsp "Password: " password
echo

qpdf --encrypt "$password" "$password" 256 -- "$input" "$output"
echo "Encrypted: $output"
