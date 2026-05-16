# wherebin - resolve the real path of a binary in PATH
if [[ $# != 1 ]]; then
  echo 'usage: wherebin something_in_your_path' >&2
  exit 1
fi

readlink "$(which "$1")"
