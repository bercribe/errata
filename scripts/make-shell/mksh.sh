# mksh - create a new shell script
if [ ! $# -eq 1 ]; then
  echo 'mksh takes one argument' 1>&2
  exit 1
elif [ -e "$1" ]; then
  echo "$1 already exists" 1>&2
  exit 1
fi

printf '#!/usr/bin/env bash\nset -e\nset -u\nset -o pipefail\n\n' > "$1"

chmod u+x "$1"

exec "$EDITOR" "$1"
