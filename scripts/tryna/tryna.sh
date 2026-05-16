# tryna - run a command until it succeeds
set +e
"$@"
status=$?
while [[ "$status" -ne 0 ]]; do
  sleep 0.5
  "$@"
  status=$?
done
