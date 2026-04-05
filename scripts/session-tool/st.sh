# st.sh - session tool
# launches a fuzzy find picker and opens the selected directory in tmux
# optionally takes an argument as the selected directory

# shellcheck disable=1091
source "${XDG_CONFIG_HOME:-$HOME/.config}/session-tool/session-tool.env" || true

IFS=: read -ra _dirs <<< "$ST_DIRS"
readarray -t dirs < <(printf '%s\n' "${_dirs[@]}" | sort -u)
IFS=' ' read -ra fd_flags <<< "$ST_FD_FLAGS"

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
