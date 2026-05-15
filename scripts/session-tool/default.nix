{
  fd,
  fzf,
  tmux,
  writeShellApplication,
}:
writeShellApplication {
  name = "st";
  runtimeInputs = [tmux fd fzf];
  text = builtins.readFile ./st.sh;
}
