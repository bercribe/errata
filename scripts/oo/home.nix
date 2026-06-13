{
  config,
  lib,
  ...
}: let
  cfg = config.programs.oo;
in {
  options = with lib;
  with types; {
    programs.oo = {
      enable = mkEnableOption "oo";
      vaultPath = mkOption {
        type = str;
        description = "Absolute path to the Obsidian vault directory";
        example = "/home/user/my-vault";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."oo/vault".text = cfg.vaultPath;
  };
}
