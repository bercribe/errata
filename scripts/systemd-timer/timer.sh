if systemctl --user status "user-timer-$1.timer" &>/dev/null; then
    read -rp "Replace existing $1 timer? " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    systemctl --user stop "user-timer-$1.timer"
fi
systemd-run --user --unit="user-timer-$1" --description="$1 user timer" --on-active="$1" --timer-property=AccuracySec=1s --setenv="PATH=$PATH" bash -c "notify-send 'timer complete' '$1'; sfx ringaling"
