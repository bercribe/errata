{
  curl,
  writeShellApplication,
}:
writeShellApplication {
  name = "post";
  runtimeInputs = [curl];
  text = builtins.readFile ./post.sh;
}
