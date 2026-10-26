# getsong - download songs in highest quality
exec yt-dlp -f bestaudio -o '%(title)s.%(ext)s' "$@"
