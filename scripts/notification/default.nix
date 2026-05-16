{
  libnotify,
  writeShellApplication,
}:
writeShellApplication {
  name = "notify";
  runtimeInputs = [libnotify];
  text = builtins.readFile ./notify.sh;
}
