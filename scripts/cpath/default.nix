{
  copy,
  writeShellApplication,
}:
writeShellApplication {
  name = "cpath";
  runtimeInputs = [copy];
  text = builtins.readFile ./cpath.sh;
}
