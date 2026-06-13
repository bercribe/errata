{
  python3,
  xdg-utils,
  writeShellApplication,
}:
writeShellApplication {
  name = "oo";
  runtimeInputs = [python3 xdg-utils];
  text = builtins.readFile ./oo.sh;
}
