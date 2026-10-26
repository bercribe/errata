# boop - play happy sound on success, sad sound on failure
# usage: some_command ; boop $?
#    or: boop some_command args...
set +e

if [ $# -eq 0 ]; then
  echo 'usage: command ; boop $?' >&2
  echo '   or: boop command args...' >&2
  exit 1
fi

if [ $# -eq 1 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
  # Called as: command ; boop $?
  exit_code="$1"
else
  # Called as: boop command args...
  "$@"
  exit_code=$?
fi

if [ "$exit_code" -eq 0 ]; then
  sfx success
else
  sfx failure
fi
