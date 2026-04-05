{pkgs, ...}:
pkgs.writeShellApplication {
  name = "bb";
  text = builtins.readFile ./bb.sh;
}
