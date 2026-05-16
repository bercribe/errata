{
  python3,
  writeShellApplication,
}:
writeShellApplication {
  name = "serveit";
  runtimeInputs = [python3];
  text = builtins.readFile ./serveit.sh;
}
