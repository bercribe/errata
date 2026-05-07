{pkgs, ...}:
pkgs.writeShellApplication {
  name = "pi-sync";
  runtimeInputs = [pkgs.git pkgs.rsync];
  text = builtins.readFile ./pi-sync.sh;
}
