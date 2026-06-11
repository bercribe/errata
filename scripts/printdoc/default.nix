{
  cups,
  fzf,
  pandoc,
  texliveSmall,
  writeShellApplication,
}:
writeShellApplication {
  name = "printdoc";
  runtimeInputs = [cups fzf pandoc texliveSmall];
  text = builtins.readFile ./printdoc.sh;
}
