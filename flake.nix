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

    vimPluginNames = builtins.attrNames (builtins.readDir ./vim-plugins);
    vimPluginPackages = pkgs:
      builtins.listToAttrs (map (name: {
          inherit name;
          value = pkgs.callPackage ./vim-plugins/${name} {};
        })
        vimPluginNames);

    overlay = final: prev: {
      errata = scriptPackages final // {vimPlugins = vimPluginPackages final;};
    };
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
      vma = import ./scripts/vma/home.nix;
    };
  };
}
