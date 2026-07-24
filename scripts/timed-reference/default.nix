{
  lib,
  stdenv,
  gallery-dl,
  imv,
  curl,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "timed-ref";
  runtimeInputs = [gallery-dl curl jq] ++ lib.optionals stdenv.isLinux [imv];
  text = builtins.readFile ./timed-ref.sh;
}
