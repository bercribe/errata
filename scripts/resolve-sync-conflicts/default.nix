{pkgs, ...}:
pkgs.writeShellApplication {
  name = "rsc";
  runtimeInputs = with pkgs; [fzf delta bat];
  text = builtins.readFile ./rsc.sh;
}
