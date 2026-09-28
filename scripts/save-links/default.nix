{
  curl,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "save-links";
  runtimeInputs = [curl jq];
  text = builtins.readFile ./save-links.sh;
}
