# ago - print the time OFFSET ago (default: now) as "Y-M-D H:M:S"
usage() {
  echo "usage: ago [-e] [OFFSET]" >&2
  echo "  OFFSET: number with optional suffix, 90s or 5m (bare number = minutes)" >&2
  echo "  -e: print epoch milliseconds" >&2
  exit "${1:-1}"
}

epoch=0
offset=""
for arg in "$@"; do
  case "$arg" in
    -e) epoch=1 ;;
    -h|--help) usage 0 ;;
    *) offset="$arg" ;;
  esac
done

secs=0
if [[ -n "$offset" ]]; then
  if [[ "$offset" =~ ^([0-9]+)([sm]?)$ ]]; then
    secs="${BASH_REMATCH[1]}"
    [[ "${BASH_REMATCH[2]}" != s ]] && secs=$((secs * 60))
  else
    usage
  fi
fi

ts=$(($(date +%s) - secs))
if ((epoch)); then
  echo "$((ts * 1000))"
else
  date -d "@$ts" '+%Y-%m-%d %H:%M:%S'
fi
