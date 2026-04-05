{pkgs, ...}:
pkgs.writeShellApplication {
  name = "tsl";
  runtimeInputs = [pkgs.tmux];
  text = builtins.readFile ./tsl.sh;
}
