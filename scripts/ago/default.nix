{
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "ago";
  runtimeInputs = [coreutils];
  text = builtins.readFile ./ago.sh;
}
