{
  pulseaudio,
  writeShellApplication,
}:
writeShellApplication {
  name = "asw";
  runtimeInputs = [pulseaudio];
  text = builtins.readFile ./asw.sh;
}
