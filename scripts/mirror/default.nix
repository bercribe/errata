{
  util-linux,
  writeShellApplication,
}:
writeShellApplication {
  name = "mirror";
  runtimeInputs = [util-linux];
  text = builtins.readFile ./mirror.sh;
}
