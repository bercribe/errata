opener=${OPENER:-$(command -v xdg-open || command -v open || command -v echo)}
for f in "$@"; do $opener "$f" 2>/dev/null || echo "$f"; done
