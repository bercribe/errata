{
  tmux,
  writeShellApplication,
}:
writeShellApplication {
  name = "twl";
  runtimeInputs = [tmux];
  text = builtins.readFile ./twl.sh;
}
