{writeShellApplication}:
writeShellApplication {
  name = "line";
  text = builtins.readFile ./line.sh;
}
