{
  pasta,
  writeShellApplication,
}:
writeShellApplication {
  name = "pastas";
  runtimeInputs = [pasta];
  text = builtins.readFile ./pastas.sh;
}
