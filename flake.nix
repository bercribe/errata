{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    scriptNames = builtins.attrNames (builtins.readDir ./scripts);
    scriptPackages = pkgs:
      builtins.listToAttrs (map (name: {
          inherit name;
          value = pkgs.callPackage ./scripts/${name} {};
        })
        scriptNames);

    overlay = final: prev:
      scriptPackages final;
    pkgsF = system:
      import nixpkgs {
        inherit system;
        overlays = [overlay];
      };
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsF system;
    in
      scriptPackages pkgs);

    overlays.default = overlay;

    homeModules = {
      file-actions = import ./scripts/file-actions/home.nix;
      mirror = import ./scripts/mirror/home.nix;
      oo = import ./scripts/oo/home.nix;
      session-tool = import ./scripts/session-tool/home.nix;
      sfx = import ./scripts/sfx/home.nix;
      snippets = import ./scripts/snippets/home.nix;
    };

    apps = forAllSystems (
      system: let
        pkgs = pkgsF system;
      in {
        shaderGallery = let
          python = pkgs.python3.withPackages (python-pkgs:
            with python-pkgs; [
            ]);
          pythonCmd = pkgs.lib.getExe python;
          program = pkgs.writeShellScriptBin "shader-server" ''
            cd ./graphics/
            ${pythonCmd} server.py
          '';
        in {
          type = "app";
          program = pkgs.lib.getExe program;
        };
      }
    );
  };
}
