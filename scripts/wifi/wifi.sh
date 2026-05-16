# wifi - control wifi
wifi_off() {
  if hash nmcli 2>/dev/null; then
    nmcli radio wifi off
  elif [[ "$(uname)" == 'Darwin' ]]; then
    networksetup -setairportpower en0 off
  else
    sudo rfkill block wifi
  fi
}

wifi_on() {
  if hash nmcli 2>/dev/null; then
    nmcli radio wifi on
  elif [[ "$(uname)" == 'Darwin' ]]; then
    networksetup -setairportpower en0 on
  else
    sudo rfkill unblock wifi
  fi
}

wifi_toggle() {
  wifi_off
  sleep 1
  wifi_on
}

help() {
  echo 'wifi off      turn off wifi'
  echo 'wifi on       turn on wifi'
  echo 'wifi toggle   turn off wifi, then on'
  echo 'wifi help     show this message'
}

if [[ $# == 0 ]]; then
  help
  exit 0
fi

case "$1" in
  help)    help ;;
  off)     wifi_off ;;
  on)      wifi_on ;;
  toggle)  wifi_toggle ;;
  *)       echo "unknown command: $1" >&2; exit 1 ;;
esac
