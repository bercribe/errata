{
  libnotify,
  sfx,
  writeShellApplication,
}:
writeShellApplication {
  name = "timer";
  runtimeInputs = [libnotify sfx];
  text = builtins.readFile ./timer.sh;
}
