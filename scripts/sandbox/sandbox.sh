# sandbox - start or stop the sources sandbox microvm
usage() {
  echo 'usage:'
  echo '  sandbox start     # start the sandbox'
  echo '  sandbox stop      # stop the sandbox'
  echo '  sandbox restart   # restart the sandbox'
  echo '  sandbox status    # check sandbox status'
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

case "$1" in
  start)
    echo 'Starting sandbox...'
    systemctl start microvm@sources.service
    echo 'Sandbox started.'
    ;;
  stop)
    echo 'Stopping sandbox...'
    systemctl stop microvm@sources.service
    echo 'Sandbox stopped.'
    ;;
  restart)
    echo 'Restarting sandbox...'
    systemctl restart microvm@sources.service
    echo 'Sandbox restarted.'
    ;;
  status)
    systemctl status microvm@sources.service
    ;;
  *)
    usage
    ;;
esac
