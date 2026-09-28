# save-links - save one or more URLs as bookmarks in readeck
# usage: save-links <url> [url2 ...]
#        save-links -           (read urls from stdin, one per line)

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/readeck"
TOKEN_FILE="${CONFIG_DIR}/api_key"
URL_FILE="${CONFIG_DIR}/url"

usage() {
  echo "Usage: save-links <url> [url2 ...]"
  echo "       save-links -   (read urls from stdin, one per line)"
  echo ""
  echo "Save one or more URLs as bookmarks in Readeck."
  echo "API token is read from ${TOKEN_FILE}"
  echo "Base URL (e.g. https://readeck.example.com) is read from ${URL_FILE},"
  echo "or overridden with the READECK_URL environment variable."
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "Error: API token not found at ${TOKEN_FILE}" >&2
  exit 1
fi
token=$(<"$TOKEN_FILE")

base_url="${READECK_URL:-}"
if [[ -z "$base_url" ]]; then
  if [[ -f "$URL_FILE" ]]; then
    base_url=$(<"$URL_FILE")
  else
    echo "Error: base URL not found at ${URL_FILE} (or set READECK_URL)" >&2
    exit 1
  fi
fi
base_url="${base_url%/}"

if [[ "${1:-}" == "-" ]]; then
  mapfile -t urls < <(grep -v '^\s*$')
else
  urls=("$@")
fi

status=0
for url in "${urls[@]}"; do
  echo "Saving: ${url}" >&2
  http_code=$(curl -sS -o /tmp/save-links-response.$$ -w "%{http_code}" \
    -X POST \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    "${base_url}/api/bookmarks" \
    -d "$(jq -n --arg url "$url" '{url: $url}')")

  if [[ "$http_code" != "202" && "$http_code" != "201" ]]; then
    echo "Error: failed to save ${url} (HTTP ${http_code})" >&2
    cat /tmp/save-links-response.$$ >&2
    status=1
  fi
  rm -f /tmp/save-links-response.$$
done

exit $status
