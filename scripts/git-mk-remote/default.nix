{
  git,
  openssh,
  writeShellApplication,
}:
writeShellApplication {
  name = "git-mk-remote";
  runtimeInputs = [git openssh];
  text = builtins.readFile ./git-mk-remote.sh;
}
