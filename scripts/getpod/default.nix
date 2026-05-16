{
  yt-dlp,
  writeShellApplication,
}:
writeShellApplication {
  name = "getpod";
  runtimeInputs = [yt-dlp];
  text = builtins.readFile ./getpod.sh;
}
