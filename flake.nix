{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
      mirror = import ./scripts/mirror/home.nix;
      session-tool = import ./scripts/session-tool/home.nix;
      sfx = import ./scripts/sfx/home.nix;
      snippets = import ./scripts/snippets/home.nix;
    };
  };
}
