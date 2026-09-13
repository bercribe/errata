{
  lib,
  libnotify,
  stdenv,
  writeShellApplication,
}:
writeShellApplication {
  name = "notify";
  runtimeInputs = lib.optionals stdenv.isLinux [libnotify];
  text = builtins.readFile ./notify.sh;
}
