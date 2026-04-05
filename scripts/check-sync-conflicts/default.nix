{
  lib,
  python3Packages,
  difftastic,
}:
python3Packages.buildPythonPackage {
  pname = "check-sync-conflicts";
  version = "0.1.0";
  format = "other";

  src = ./.;

  installPhase = ''
    mkdir -p $out/bin
    cp csc.py $out/bin/csc
    chmod +x $out/bin/csc
  '';

  makeWrapperArgs = ["--prefix PATH : ${lib.makeBinPath [difftastic]}"];
}
