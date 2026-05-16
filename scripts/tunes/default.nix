{
  mpv,
  writeShellApplication,
}:
writeShellApplication {
  name = "tunes";
  runtimeInputs = [mpv];
  text = builtins.readFile ./tunes.sh;
}
