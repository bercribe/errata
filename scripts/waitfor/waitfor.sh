# waitfor - wait for a PID to exit, preventing sleep
pid="$1"

if hash systemd-inhibit 2>/dev/null; then
  systemd-inhibit \
    --who=waitfor \
    --why="Awaiting PID $pid" \
    tail --pid="$pid" -f /dev/null
elif hash caffeinate 2>/dev/null; then
  caffeinate -w "$pid"
else
  tail --pid="$pid" -f /dev/null
fi
