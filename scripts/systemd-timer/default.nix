{pkgs, ...}:
pkgs.writeShellApplication {
  name = "timer";
  runtimeInputs = [pkgs.libnotify];
  text = builtins.readFile ./timer.sh;
}
