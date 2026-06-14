{
  cups,
  fzf,
  pandoc,
  texliveSmall,
  writeShellApplication,
}:
writeShellApplication {
  name = "printdoc";
  runtimeInputs = [cups fzf pandoc texliveSmall];
  runtimeEnv.PRINTDOC_LUA_FILTER = "${./strip-codeblocks.lua}";
  text = builtins.readFile ./printdoc.sh;
}
