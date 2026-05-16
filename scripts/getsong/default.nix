{
  yt-dlp,
  writeShellApplication,
}:
writeShellApplication {
  name = "getsong";
  runtimeInputs = [yt-dlp];
  text = builtins.readFile ./getsong.sh;
}
