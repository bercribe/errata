{pkgs, ...}:
pkgs.writeShellApplication {
  name = "twl";
  runtimeInputs = [pkgs.tmux];
  text = builtins.readFile ./twl.sh;
}
