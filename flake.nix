{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f:
      builtins.listToAttrs (map (system: {
          name = system;
          value = f system;
        })
        systems);

    scriptNames = builtins.attrNames (builtins.readDir ./scripts);
    scriptPackages = pkgs:
      builtins.listToAttrs (map (name: {
          inherit name;
          value = pkgs.callPackage ./scripts/${name} {};
        })
        scriptNames);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      scriptPackages pkgs);

    overlays.default = final: prev:
      scriptPackages final;

    homeModules = {
      st = import ./scripts/st/home.nix;
    };
  };
}
