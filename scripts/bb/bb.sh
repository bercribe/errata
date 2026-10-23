# https://evanhahn.com/scripts-i-wrote-that-i-use-all-the-time/
nohup "$@" &>/dev/null &
disown
