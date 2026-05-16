{writeShellApplication}:
writeShellApplication {
  name = "catbin";
  text = builtins.readFile ./catbin.sh;
}
