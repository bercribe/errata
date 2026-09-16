{
  openssh,
  writeShellApplication,
}:
writeShellApplication {
  name = "vma";
  runtimeInputs = [openssh];
  text = builtins.readFile ./vma.sh;
}
