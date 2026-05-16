{writeShellApplication}:
writeShellApplication {
  name = "tryna";
  text = builtins.readFile ./tryna.sh;
}
