# vma - virtual machine agent quick connect
# ssh into a configured host, pick a session with st, then launch pi
#
# Config: ~/.config/vma/host

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/vma/host"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: host not configured. Set programs.vma.host in home-manager." >&2
    exit 1
fi

host=$(<"$CONFIG_FILE")

exec ssh -t "$host" 'STARTUP_CMD=pi st'
