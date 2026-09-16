{
  config,
  lib,
  ...
}: let
  cfg = config.programs.vma;
in {
  options = with lib;
  with types; {
    programs.vma = {
      enable = mkEnableOption "vma";
      host = mkOption {
        type = str;
        description = "SSH destination to connect to";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."vma/host".text = cfg.host;
  };
}
