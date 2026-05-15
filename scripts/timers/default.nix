{writeShellApplication}:
writeShellApplication {
  name = "timers";
  text = builtins.readFile ./timers.sh;
}
