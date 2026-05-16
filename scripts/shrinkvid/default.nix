{
  ffmpeg,
  writeShellApplication,
}:
writeShellApplication {
  name = "shrinkvid";
  runtimeInputs = [ffmpeg];
  text = builtins.readFile ./shrinkvid.sh;
}
