# shrinkvid - compress a video with ffmpeg
if [ $# -lt 2 ]; then
  echo 'usage: shrinkvid input.mp4 output.mp4 [crf]' >&2
  exit 1
fi

exec ffmpeg -i "$1" -c:v libx264 -tag:v avc1 -movflags faststart -crf "${3:-30}" -preset superfast "$2"
