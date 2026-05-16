{
  sfx,
  writeShellApplication,
}:
writeShellApplication {
  name = "boop";
  runtimeInputs = [sfx];
  text = builtins.readFile ./boop.sh;
}
