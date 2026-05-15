{
  libnotify,
  writeShellApplication,
}:
writeShellApplication {
  name = "timer";
  runtimeInputs = [libnotify];
  text = builtins.readFile ./timer.sh;
}
