# getpod - download audio for podcast listening
exec yt-dlp \
  --embed-chapters \
  --embed-thumbnail \
  --extract-audio \
  --audio-format mp3 \
  -f worstaudio \
  "$@"
