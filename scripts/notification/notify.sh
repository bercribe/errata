# notify - send an OS notification
title="${1:-Notification}"
description="${2:-$(date --iso-8601=seconds)}"

if hash notify-send 2>/dev/null; then
  exec notify-send --expire-time=5000 "$title" "$description"
else
  echo "can't send notifications" >&2
  exit 1
fi
