{
  writeShellApplication,
}:
writeShellApplication {
  name = "mktrash";
  text = builtins.readFile ./mktrash.sh;
}
