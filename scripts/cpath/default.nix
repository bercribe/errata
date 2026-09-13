{
  errata,
  writeShellApplication,
}:
writeShellApplication {
  name = "cpath";
  runtimeInputs = [errata.copy];
  text = builtins.readFile ./cpath.sh;
}
