{writeShellApplication}:
writeShellApplication {
  name = "opn";
  text = builtins.readFile ./opn.sh;
}
