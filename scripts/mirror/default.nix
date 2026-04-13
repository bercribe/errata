{pkgs, ...}:
pkgs.writeShellApplication {
  name = "mirror";
  runtimeInputs = [pkgs.util-linux];
  text = builtins.readFile ./mirror.sh;
}
