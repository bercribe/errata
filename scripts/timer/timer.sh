# timer - schedule a notification + sound after a delay
# usage: timer <duration>
# on Linux, runs via systemd-run so it shows up in `timers`
# on macOS, backgrounds a plain sleep since systemd is unavailable there

if command -v systemctl &>/dev/null; then
    if systemctl --user status "user-timer-$1.timer" &>/dev/null; then
        read -rp "Replace existing $1 timer? " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
        systemctl --user stop "user-timer-$1.timer"
    fi
    systemd-run --user --unit="user-timer-$1" --description="$1 user timer" --on-active="$1" --timer-property=AccuracySec=1s --setenv="PATH=$PATH" bash -c "notify 'timer complete' '$1'; sfx ringaling"
else
    sleep "$1"
    sfx ringaling
    notify 'timer complete' "$1"
fi
