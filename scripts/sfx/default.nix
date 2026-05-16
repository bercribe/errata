{
  mpv,
  writeShellApplication,
}:
writeShellApplication {
  name = "sfx";
  runtimeInputs = [mpv];
  text = builtins.readFile ./sfx.sh;
}
