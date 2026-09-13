{
  errata,
  writeShellApplication,
}:
writeShellApplication {
  name = "pastas";
  runtimeInputs = [errata.pasta];
  text = builtins.readFile ./pastas.sh;
}
