{pkgs, ...}:
pkgs.writeShellApplication {
  name = "encrypt-pdf";
  runtimeInputs = [pkgs.qpdf];
  text = builtins.readFile ./encrypt-pdf.sh;
}
