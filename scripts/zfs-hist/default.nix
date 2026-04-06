{pkgs, ...}:
pkgs.writeShellApplication {
  name = "zvb";
  runtimeInputs = with pkgs; [fzf delta bat];
  text = builtins.readFile ./zvb.sh;
}
