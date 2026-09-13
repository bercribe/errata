{writeShellApplication}:
writeShellApplication {
  name = "gcm";
  text = builtins.readFile ./gcm.sh;
}
