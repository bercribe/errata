{
  getopt,
  git,
  writeShellApplication,
}:
writeShellApplication {
  name = "gtgh";
  runtimeInputs = [git getopt];
  text = builtins.readFile ./gtgh.sh;
}
