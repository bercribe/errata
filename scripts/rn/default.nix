{writeShellApplication}:
writeShellApplication {
  name = "rn";
  text = builtins.readFile ./rn.sh;
}
