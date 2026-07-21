# timed-ref - timed reference drawing practice from images
interval=60
count=5
source=""

usage() {
  echo "usage: timed-ref [-t seconds] [-n num-images] <url-or-dir>" >&2
  echo "  -t  seconds per image (default: 60)" >&2
  echo "  -n  number of images (default: 5)" >&2
  exit 1
}

while getopts "t:n:h" opt; do
  case "$opt" in
    t) interval="$OPTARG" ;;
    n) count="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

source="${1:-}"
[ -z "$source" ] && usage

if [ -d "$source" ]; then
  img_dir="$source"
else
  url_path=$(echo "$source" | sed 's|^https\?://||; s|/$||')
  img_dir="$HOME/Pictures/timed-ref/$url_path"

  mkdir -p "$img_dir"
  echo "Downloading images from: $source"
  gallery-dl -D "$img_dir" "$source"
fi

images=()
while IFS= read -r -d '' file; do
  images+=("$file")
done < <(find "$img_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) -print0 | sort -z -R)

if [ ${#images[@]} -eq 0 ]; then
  echo "No images found" >&2
  exit 1
fi

images=("${images[@]:0:$count}")

echo "Selected ${#images[@]} images, ${interval}s per image"
echo "Press enter to start..."
read -r

viewer_pid=""
cleanup() {
  [ -n "$viewer_pid" ] && kill "$viewer_pid" 2>/dev/null || true
}
trap cleanup EXIT

is_mac=$([ "$(uname)" = "Darwin" ] && echo 1 || echo 0)

show_image() {
  if [ "$is_mac" -eq 1 ]; then
    [ -n "$viewer_pid" ] && kill "$viewer_pid" 2>/dev/null || true
    qlmanage -p "$1" &>/dev/null &
    viewer_pid=$!
  elif [ -z "$viewer_pid" ]; then
    imv -f "$1" &
    viewer_pid=$!
    sleep 0.5
  else
    imv-msg "$viewer_pid" open "$1"
    imv-msg "$viewer_pid" close 1
  fi
}

warn_timer() {
  warn=5
  if [ "$is_mac" -eq 1 ]; then
    sleep "$interval"
  elif [ "$interval" -gt "$warn" ]; then
    sleep $((interval - warn))
    imv-msg "$viewer_pid" background 331111
    sleep "$warn"
    imv-msg "$viewer_pid" background 000000
  else
    sleep "$interval"
  fi
}

for i in "${!images[@]}"; do
  img="${images[$i]}"
  num=$((i + 1))
  echo "[${num}/${#images[@]}] $(basename "$img") - ${interval}s"
  show_image "$img"
  warn_timer
done

echo "Done!"
