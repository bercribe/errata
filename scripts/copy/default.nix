{writeShellApplication}:
writeShellApplication {
  name = "copy";
  text = builtins.readFile ./copy.sh;
}
