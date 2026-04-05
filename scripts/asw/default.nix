{pkgs, ...}:
pkgs.writeShellApplication {
  name = "asw";
  runtimeInputs = [pkgs.pulseaudio];
  text = builtins.readFile ./asw.sh;
}
