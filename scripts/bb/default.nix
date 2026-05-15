{writeShellApplication}:
writeShellApplication {
  name = "bb";
  text = builtins.readFile ./bb.sh;
}
