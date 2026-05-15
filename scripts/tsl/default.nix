{
  tmux,
  writeShellApplication,
}:
writeShellApplication {
  name = "tsl";
  runtimeInputs = [tmux];
  text = builtins.readFile ./tsl.sh;
}
