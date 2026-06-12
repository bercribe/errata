{
  fzf,
  writeShellApplication,
}:
writeShellApplication {
  name = "fa";
  runtimeInputs = [fzf];
  text = builtins.readFile ./fa.sh;
}
