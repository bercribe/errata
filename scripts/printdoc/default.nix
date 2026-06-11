{
  cups,
  fzf,
  writeShellApplication,
}:
writeShellApplication {
  name = "printdoc";
  runtimeInputs = [cups fzf];
  text = builtins.readFile ./printdoc.sh;
}
