# pastas - watch clipboard for changes
trap 'exit 0' SIGINT

last_value=''

while true; do
  value="$(pasta)"

  if [ "$last_value" != "$value" ]; then
    echo "$value"
    last_value="$value"
  fi

  sleep 0.1
done
