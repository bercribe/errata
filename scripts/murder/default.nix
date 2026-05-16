{
  lsof,
  writeShellApplication,
}:
writeShellApplication {
  name = "murder";
  runtimeInputs = [lsof];
  text = builtins.readFile ./murder.sh;
}
