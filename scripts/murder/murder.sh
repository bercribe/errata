# murder - gracefully kill processes by pid, name, or port
if [ $# -lt 1 ]; then
  echo 'usage:'
  echo '  murder 123    # kill by pid'
  echo '  murder ruby   # kill by process name'
  echo '  murder :3000  # kill by port'
  exit 1
fi

murder_pid() {
  local pid="$1"
  for sig in 15 2 1 9; do
    if ! ps -p "$pid" &>/dev/null; then return 0; fi
    kill "-$sig" "$pid" 2>/dev/null || true
    sleep 0.5
    if ps -p "$pid" &>/dev/null; then sleep 3; fi
  done
}

murder_name() {
  pgrep -fi "$1" | while read -r pid; do
    [[ "$pid" == "$$" ]] && continue
    cmd="$(ps -p "$pid" -o command= 2>/dev/null || echo "unknown")"
    read -rp "murder $cmd (pid $pid)? " confirm </dev/tty
    if [[ "$confirm" =~ ^[Yy] ]]; then
      murder_pid "$pid"
    fi
  done
}

murder_port() {
  local port="${1#:}"
  lsof -i ":$port" 2>/dev/null | tail -n +2 | while read -r _ pid _rest; do
    cmd="$(ps -p "$pid" -o command= 2>/dev/null || echo "unknown")"
    read -rp "murder $cmd (pid $pid)? " confirm </dev/tty
    if [[ "$confirm" =~ ^[Yy] ]]; then
      murder_pid "$pid"
    fi
  done
}

for arg in "$@"; do
  if [[ "$arg" =~ ^[0-9]+$ ]]; then
    murder_pid "$arg"
  elif [[ "$arg" == :* ]]; then
    murder_port "$arg"
  else
    murder_name "$arg"
  fi
done
