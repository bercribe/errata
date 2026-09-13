{
  curl,
  errata,
  jq,
  pandoc,
  pocket-tts,
  writeShellApplication,
}:
writeShellApplication {
  name = "generate-pod";
  runtimeInputs = [curl jq pandoc pocket-tts errata.straightquote];
  text = builtins.readFile ./generate-pod.sh;
}
