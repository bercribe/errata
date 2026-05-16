{writeShellApplication}:
writeShellApplication {
  name = "hoy";
  text = builtins.readFile ./hoy.sh;
}
