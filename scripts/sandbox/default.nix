{
  writeShellApplication,
}:
writeShellApplication {
  name = "sandbox";
  text = builtins.readFile ./sandbox.sh;
}
