# vman.sh - open a man page in neovim
if [ $# -eq 0 ]; then
    echo "Usage: vman [section] <page>"
    exit 1
fi

nvim "+Man $*" "+only"
