# getsubs - download English subtitles for a video
if [ $# -ne 1 ]; then
  echo 'usage: getsubs <url>' >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

try_download() {
  yt-dlp \
    --skip-download \
    "$1" \
    --sub-lang en \
    --sub-format vtt \
    -o "$tmpdir/%(id)s.%(ext)s" \
    "$2" 2>/dev/null

  for f in "$tmpdir"/*.vtt; do
    if [ -f "$f" ]; then
      # Strip VTT headers, timestamps, and inline tags, deduplicate consecutive lines
      sed '/^WEBVTT/d; /^Kind:/d; /^Language:/d; /^$/d; /^[0-9][0-9]:/d; /-->/d; s/<[^>]*>//g; /^[[:space:]]*$/d' "$f" \
        | awk 'prev != $0 { print; prev = $0 }'
      return 0
    fi
  done
  return 1
}

try_download --write-sub "$1" || try_download --write-auto-sub "$1" || {
  echo 'no subs found' >&2
  exit 1
}
