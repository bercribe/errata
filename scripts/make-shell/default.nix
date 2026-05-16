{writeShellApplication}:
writeShellApplication {
  name = "mksh";
  text = builtins.readFile ./mksh.sh;
}
