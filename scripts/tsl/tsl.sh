# tsl.sh - tmux switch layout
tmux select-layout "$(cat "$HOME/.config/tmux/$1.layout")"
