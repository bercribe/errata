{writeShellApplication}:
writeShellApplication {
  name = "snippets";
  text = builtins.readFile ./snippets.sh;
}
