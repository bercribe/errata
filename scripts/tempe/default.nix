{writeShellApplication}:
writeShellApplication {
  name = "tempe";
  text = builtins.readFile ./tempe.sh;
}
