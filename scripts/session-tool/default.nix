{pkgs, ...}:
pkgs.writeShellApplication {
  name = "st";
  runtimeInputs = [pkgs.tmux pkgs.fd pkgs.fzf];
  text = builtins.readFile ./st.sh;
}
