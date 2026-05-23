{
  curl,
  jq,
  pandoc,
  pocket-tts,
  straightquote,
  writeShellApplication,
}:
writeShellApplication {
  name = "generate-pod";
  runtimeInputs = [curl jq pandoc pocket-tts straightquote];
  text = builtins.readFile ./generate-pod.sh;
}
