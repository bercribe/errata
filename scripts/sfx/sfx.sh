# sfx - play a sound effect
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
exec mpv --really-quiet --no-video "$XDG_CONFIG_HOME/sfx/$1.mp3"
