# st.sh - session tool
# launches a fuzzy find picker and opens the selected directory in tmux
# optionally takes an argument as the selected directory
#
# Config: ~/.config/session-tool/session-tool.conf
#   directories=/path/one:/path/two
#   fd_flags=--flag1 --flag2

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/session-tool/session-tool.conf"

load_directories() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: config file not found: $CONFIG_FILE"
        exit 1
    fi
    local raw
    raw=$(grep -E '^directories=' "$CONFIG_FILE" | head -1 | cut -d= -f2-)
    if [[ -z "$raw" ]]; then
        echo "Error: 'directories' not set in $CONFIG_FILE"
        exit 1
    fi
    eval echo "$raw"
}

load_fd_flags() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return
    fi
    local raw
    raw=$(grep -E '^fd_flags=' "$CONFIG_FILE" | head -1 | cut -d= -f2-)
    eval echo "$raw"
}

IFS=: read -ra _dirs <<< "$(load_directories)"
readarray -t dirs < <(printf '%s\n' "${_dirs[@]}" | sort -u)
IFS=' ' read -ra fd_flags <<< "$(load_fd_flags)"

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(fd . "${dirs[@]}" --type=dir --max-depth=1 "${fd_flags[@]}" 2>/dev/null |
    fzf --no-sort --delimiter / --with-nth -3..)
fi

[[ ! $selected ]] && exit 0

path="$selected"
session_name=$(basename "$path" | tr . _)

if ! tmux has-session -t "$session_name"; then
    tmux new-session -ds "$session_name" -c "$path"
fi

if [[ -z ${TMUX:-} ]]; then
    tmux a -t "$session_name"
else
    tmux switch-client -t "$session_name"
fi
