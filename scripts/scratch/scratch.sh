# scratch - open a temporary editor buffer
file="$(mktemp)"
echo "Editing $file"
exec "$EDITOR" "$file"
