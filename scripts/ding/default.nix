{
  writeShellApplication,
}:
writeShellApplication {
  name = "ding";
  text = builtins.readFile ./ding.sh;
}
