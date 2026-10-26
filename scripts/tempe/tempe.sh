# tempe - cd to a temporary directory in a new shell
dir="$(mktemp -d)"
echo "$dir"
cd "$dir"
exec "$SHELL"
