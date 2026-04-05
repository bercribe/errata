{pkgs, ...}:
pkgs.writeShellApplication {
  name = "gtgh";
  runtimeInputs = [pkgs.git pkgs.getopt];
  text = builtins.readFile ./gtgh.sh;
}
