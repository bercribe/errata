{
  calibre,
  curl,
  writeShellApplication,
}:
writeShellApplication {
  name = "epub-clean";
  runtimeInputs = [calibre];
  text = builtins.readFile ./epub-clean.sh;
}
