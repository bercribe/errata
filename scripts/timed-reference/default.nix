{
  gallery-dl,
  imv,
  writeShellApplication,
}:
writeShellApplication {
  name = "timed-ref";
  runtimeInputs = [gallery-dl imv];
  text = builtins.readFile ./timed-ref.sh;
}
