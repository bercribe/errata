{
  git,
  writeShellApplication,
}:
writeShellApplication {
  name = "git-resync";
  runtimeInputs = [git];
  text = builtins.readFile ./git-resync.sh;
}
