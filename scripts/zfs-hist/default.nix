{pkgs, ...}:
pkgs.writeShellApplication {
  name = "vb";
  runtimeInputs = with pkgs; [fzf delta bat];
  text = builtins.readFile ./vb.sh;
}
