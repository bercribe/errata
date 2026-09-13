{writeShellApplication}:
writeShellApplication {
  name = "gbr";
  text = builtins.readFile ./gbr.sh;
}
