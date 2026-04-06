{pkgs, ...}:
pkgs.writeShellApplication {
  name = "rsc";
  runtimeInputs = with pkgs; [fzf delta bat neovim];
  text = builtins.readFile ./rsc.sh;
}
