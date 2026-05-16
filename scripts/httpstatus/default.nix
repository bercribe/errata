{writeShellApplication}:
writeShellApplication {
  name = "httpstatus";
  text = builtins.readFile ./httpstatus.sh;
}
