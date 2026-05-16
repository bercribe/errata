{writeShellApplication}:
writeShellApplication {
  name = "wherebin";
  text = builtins.readFile ./wherebin.sh;
}
