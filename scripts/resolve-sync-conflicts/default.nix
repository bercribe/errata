{
  bat,
  delta,
  fzf,
  writeShellApplication,
}:
writeShellApplication {
  name = "rsc";
  runtimeInputs = [fzf delta bat];
  text = builtins.readFile ./rsc.sh;
}
