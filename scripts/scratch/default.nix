{writeShellApplication}:
writeShellApplication {
  name = "scratch";
  text = builtins.readFile ./scratch.sh;
}
