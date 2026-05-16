{
  espeak-ng,
  pandoc,
  writeShellApplication,
}:
writeShellApplication {
  name = "speak";
  runtimeInputs = [pandoc espeak-ng];
  text = builtins.readFile ./speak.sh;
}
