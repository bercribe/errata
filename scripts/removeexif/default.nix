{
  jhead,
  writeShellApplication,
}:
writeShellApplication {
  name = "removeexif";
  runtimeInputs = [jhead];
  text = builtins.readFile ./removeexif.sh;
}
