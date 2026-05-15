{
  bat,
  delta,
  fzf,
  writeShellApplication,
}:
writeShellApplication {
  name = "zvb";
  runtimeInputs = [fzf delta bat];
  text = builtins.readFile ./zvb.sh;
}
