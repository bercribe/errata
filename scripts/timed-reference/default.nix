{
  lib,
  stdenv,
  gallery-dl,
  imv,
  writeShellApplication,
}:
writeShellApplication {
  name = "timed-ref";
  runtimeInputs = [gallery-dl] ++ lib.optionals stdenv.isLinux [imv];
  text = builtins.readFile ./timed-ref.sh;
}
