{
  git,
  rsync,
  writeShellApplication,
}:
writeShellApplication {
  name = "pi-sync";
  runtimeInputs = [git rsync];
  text = builtins.readFile ./pi-sync.sh;
}
