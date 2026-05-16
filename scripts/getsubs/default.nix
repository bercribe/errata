{
  yt-dlp,
  writeShellApplication,
}:
writeShellApplication {
  name = "getsubs";
  runtimeInputs = [yt-dlp];
  text = builtins.readFile ./getsubs.sh;
}
