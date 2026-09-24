{
  gh,
  git,
  writeShellApplication,
}:
writeShellApplication {
  name = "pr-review";
  runtimeInputs = [gh git];
  text = builtins.readFile ./pr-review.sh;
}
