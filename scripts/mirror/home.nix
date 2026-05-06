{
  config,
  lib,
  ...
}: let
  cfg = config.programs.mirror;
in {
  options = with lib;
  with types; {
    programs.mirror = {
      enable = mkEnableOption "mirror";
      target = mkOption {
        type = str;
        description = "Default target directory to mirror to";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."mirror/mirror.conf" = {
      text = ''
        target=${cfg.target}
      '';
    };
  };
}
