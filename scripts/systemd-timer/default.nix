{
  errata,
  libnotify,
  writeShellApplication,
}:
writeShellApplication {
  name = "timer";
  runtimeInputs = [libnotify errata.sfx];
  text = builtins.readFile ./timer.sh;
}
