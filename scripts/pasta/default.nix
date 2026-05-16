{writeShellApplication}:
writeShellApplication {
  name = "pasta";
  text = builtins.readFile ./pasta.sh;
}
