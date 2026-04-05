{pkgs, ...}:
pkgs.writeShellApplication {
  name = "opn";
  text = builtins.readFile ./opn.sh;
}
