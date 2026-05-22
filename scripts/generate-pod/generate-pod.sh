# generate-pod - generate a podcast from a readeck article using pocket-tts
# usage: generate-pod <readeck-url> [output.wav]

set -euo pipefail

TOKEN_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/readeck/api_key"

usage() {
  echo "Usage: generate-pod <readeck-url> [output.wav]"
  echo ""
  echo "Generate a podcast audio file from a Readeck article."
  echo "API token is read from ${TOKEN_FILE}"
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

url="$1"

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "Error: API token not found at ${TOKEN_FILE}" >&2
  exit 1
fi
token=$(<"$TOKEN_FILE")

# Derive base_url and uid from the supplied URL
# Readeck URLs: https://host/bookmarks/{uid} or https://host/bookmarks/{uid}/...
uid=$(echo "$url" | grep -oP '/bookmarks/\K[a-zA-Z0-9]{18,22}')
if [[ -z "$uid" ]]; then
  echo "Error: could not extract bookmark UID from URL: $url" >&2
  exit 1
fi
base_url=$(echo "$url" | grep -oP '^https?://[^/]+')

echo "Fetching article ${uid}..." >&2

# Fetch title
title=$(curl -sS \
  -H "Authorization: Bearer ${token}" \
  -H "Accept: application/json" \
  "${base_url}/api/bookmarks/${uid}" \
  | jq -r '.title // "Unknown Article"')
echo "Title: ${title}" >&2

# Fetch article HTML
html=$(curl -sS -f \
  -H "Authorization: Bearer ${token}" \
  -H "Accept: text/html" \
  "${base_url}/api/bookmarks/${uid}/article")

# Convert HTML to plain text, with audible heading markers
text=$(echo "$html" \
  | pandoc -f html -t commonmark --wrap=none \
  | awk '
    /^    / {
      if (!in_block) {
        in_block = 1
        print "(Code block skipped.)"
      }
      next
    }
    /^$/ && in_block { next }
    {
      in_block = 0
      print
    }
  ' \
  | sed 's/^# \(.*\)/\1./' \
  | sed 's/^## \(.*\)/\1./' \
  | sed 's/^### \(.*\)/\1./' \
  | sed 's/^#### \(.*\)/\1./' \
  | pandoc -f commonmark -t plain --wrap=none)

if [[ -z "$text" ]]; then
  echo "Error: article text is empty" >&2
  exit 1
fi

echo "Article length: $(echo "$text" | wc -w) words" >&2

# Determine output filename
output="${2:-$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')}.wav"

echo "Generating audio with pocket-tts..." >&2
pocket-tts generate --text "$text" --voice alba --language english --output-path "$output"

echo "Saved: ${output}" >&2
