{
  errata,
  writeShellApplication,
}:
writeShellApplication {
  name = "timer";
  runtimeInputs = with errata; [notification sfx];
  text = builtins.readFile ./timer.sh;
}
