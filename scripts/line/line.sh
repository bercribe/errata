# line - print a specific line from stdin
lineno="$1"; shift
sed -n "${lineno}p" -- "$@"
