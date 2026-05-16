{writeShellApplication}:
writeShellApplication {
  name = "waitfor";
  text = builtins.readFile ./waitfor.sh;
}
