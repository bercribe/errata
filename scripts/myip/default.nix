{
  curl,
  writeShellApplication,
}:
writeShellApplication {
  name = "myip";
  runtimeInputs = [curl];
  text = builtins.readFile ./myip.sh;
}
