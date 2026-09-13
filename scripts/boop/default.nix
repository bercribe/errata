{
  errata,
  writeShellApplication,
}:
writeShellApplication {
  name = "boop";
  runtimeInputs = [errata.sfx];
  text = builtins.readFile ./boop.sh;
}
