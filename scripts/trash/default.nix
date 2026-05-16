{
  glib,
  writeShellApplication,
}:
writeShellApplication {
  name = "trash";
  runtimeInputs = [glib];
  text = builtins.readFile ./trash.sh;
}
