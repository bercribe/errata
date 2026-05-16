{writeShellApplication}:
writeShellApplication {
  name = "running";
  text = builtins.readFile ./running.sh;
}
