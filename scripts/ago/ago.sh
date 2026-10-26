# ago - print the time OFFSET ago (default: now) as "Y-M-D H:M:S"
usage() {
  echo "usage: ago [-e] [OFFSET]" >&2
  echo "  OFFSET: number with optional suffix, 90s or 5m (bare number = epoch in ms)" >&2
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

ts=$(date +%s)
if [[ -n "$offset" ]]; then
  if [[ "$offset" =~ ^([0-9]+)([sm]?)$ ]]; then
    num="${BASH_REMATCH[1]}"
    case "${BASH_REMATCH[2]}" in
      s) ts=$((ts - num)) ;;
      m) ts=$((ts - num * 60)) ;;
      "") ts=$((num / 1000)) ;;
    esac
  else
    usage
  fi
fi

if ((epoch)); then
  echo "$((ts * 1000))"
else
  date -d "@$ts" '+%Y-%m-%d %H:%M:%S'
fi
