{writeShellApplication}:
writeShellApplication {
  name = "wifi";
  text = builtins.readFile ./wifi.sh;
}
