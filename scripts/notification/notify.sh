# notify - send an OS notification
title="${1:-Notification}"
description="${2:-$(date --iso-8601=seconds)}"

if hash notify-send 2>/dev/null; then
  exec notify-send --expire-time=60000 "$title" "$description"
elif hash osascript 2>/dev/null; then
  exec osascript -e "display notification \"$description\" with title \"$title\""
else
  echo "can't send notifications" >&2
  exit 1
fi
