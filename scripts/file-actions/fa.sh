# fa - run a command on a file or directory, selected via fzf
# usage: fa [-l|-r <cmd>] <path>
# -l: list actions with $f and $d resolved
# -r <cmd>: resolve and run <cmd> against <path>
# available variables in commands: $f (path as given), $d (parent directory, or path itself if directory)

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/file-actions/actions"

mode=interactive
if [[ "${1:-}" == "-l" ]]; then
    mode=list
    shift
elif [[ "${1:-}" == "-r" ]]; then
    mode=run
    shift
    run_cmd="$1"
    shift
fi

if [[ "$mode" == "list" ]]; then
    cat "$CONFIG_FILE"
    exit 0
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: fa [-l|-r <cmd>] <path>"
    exit 1
fi

# shellcheck disable=SC2034
f="$1"
# shellcheck disable=SC2034
if [[ -d "$f" ]]; then
    d="$f"
else
    d="$(dirname "$f")"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config file not found: $CONFIG_FILE"
    exit 1
fi

resolve() {
    local cmd="$1"
    # shellcheck disable=SC2016
    if [[ "$cmd" != *'$f'* && "$cmd" != *'$d'* ]]; then
        cmd="$cmd \"$f\""
    else
        cmd="${cmd//\$f/$f}"
        cmd="${cmd//\$d/$d}"
    fi
    echo "$cmd"
}

case "$mode" in
    run)
        eval "$(resolve "$run_cmd")"
        ;;
    interactive)
        result=$(fzf --print-query < "$CONFIG_FILE" || true)
        query=$(head -1 <<< "$result")
        match=$(sed -n '2p' <<< "$result")
        cmd="${match:-$query}"
        [[ -z "$cmd" ]] && exit 0
        eval "$(resolve "$cmd")"
        ;;
esac
