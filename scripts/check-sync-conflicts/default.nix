{
  difftastic,
  lib,
  writers,
}:
writers.writePython3Bin "csc" {
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [difftastic]}"
  ];
}
(builtins.readFile ./csc.py)
