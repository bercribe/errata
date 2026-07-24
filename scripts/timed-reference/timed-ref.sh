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

fetch_karakeep_images() {
    local kk_url="$1"
    local list_id="$2"

    local kk_api_key_path kk_api_key
    kk_api_key_path="${XDG_CONFIG_HOME:-$HOME/.config}/karakeep/api_key"
    kk_api_key=$(tr -d '\n' < "$kk_api_key_path")

    local auth="Authorization: Bearer $kk_api_key"

    # fetch all bookmarks from the list, paginating
    local all_bookmarks cursor query response page_bookmarks next_cursor
    all_bookmarks="[]"
    cursor=""

    while true; do
        query=""
        [ -n "$cursor" ] && query="?cursor=$cursor"
        response=$(curl -sf -H "$auth" -H "Accept: application/json" "$kk_url/api/v1/lists/$list_id/bookmarks$query")
        page_bookmarks=$(echo "$response" | jq '.bookmarks')
        all_bookmarks=$(echo "$all_bookmarks $page_bookmarks" | jq -s 'add')
        next_cursor=$(echo "$response" | jq -r '.nextCursor // empty')
        [ -z "$next_cursor" ] && break
        cursor="$next_cursor"
    done

    # extract image asset IDs
    local asset_ids
    asset_ids=$(echo "$all_bookmarks" | jq -r '.[] | select(.content.type == "asset" and .content.assetType == "image") | .content.assetId')

    if [ -z "$asset_ids" ]; then
        echo "No image bookmarks found in list: $list_id" >&2
        exit 1
    fi

    local img_dir="$HOME/Pictures/timed-ref/karakeep/$list_id"
    mkdir -p "$img_dir"

    echo "Downloading images from karakeep list: $list_id" >&2
    local asset_id
    for asset_id in $asset_ids; do
        if ls "$img_dir/$asset_id".* > /dev/null 2>&1; then
            continue
        fi
        local headers_file
        headers_file=$(mktemp)
        local tmp_file="$img_dir/$asset_id.tmp"
        if curl -sf -H "$auth" -o "$tmp_file" -D "$headers_file" "$kk_url/api/v1/assets/$asset_id"; then
            local content_type ext
            content_type=$(grep -i '^content-type:' "$headers_file" | tr -d '\r' | awk '{print $2}')
            case "$content_type" in
                image/png) ext="png" ;;
                image/webp) ext="webp" ;;
                image/gif) ext="gif" ;;
                *) ext="jpg" ;;
            esac
            mv "$tmp_file" "$img_dir/$asset_id.$ext"
        else
            rm -f "$tmp_file"
        fi
        rm -f "$headers_file"
    done

    echo "$img_dir"
}

if [ -d "$source" ]; then
    img_dir="$source"
elif [[ "$source" == *karakeep* ]]; then
    stripped="${source#*://}"
    kk_url="${source%%://*}://${stripped%%/*}"
    list_id="${source##*/}"
    img_dir=$(fetch_karakeep_images "$kk_url" "$list_id")
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
    half=$((interval/2))
    warn=5
    if [ "$is_mac" -eq 1 ]; then
        sleep "$interval"
    else
        imv-msg "$viewer_pid" background 000000
        sleep "$half"
        imv-msg "$viewer_pid" background 444411
        if [ "$half" -gt "$warn" ]; then
            sleep $((half - warn))
            imv-msg "$viewer_pid" background 331111
            sleep "$warn"
        else
            sleep "$half"
        fi
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
