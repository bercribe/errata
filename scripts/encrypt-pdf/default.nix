{
  qpdf,
  writeShellApplication,
}:
writeShellApplication {
  name = "encrypt-pdf";
  runtimeInputs = [qpdf];
  text = builtins.readFile ./encrypt-pdf.sh;
}
