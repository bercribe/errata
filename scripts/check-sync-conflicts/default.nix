{
  writers,
  difftastic,
}:
writers.writePython3Bin "csc" {
  libraries = [difftastic];
}
(builtins.readFile ./csc.py)
