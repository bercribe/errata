{
  config,
  lib,
  ...
}: let
  cfg = config.programs.session-tool;
in {
  options = with lib;
  with types; {
    programs.session-tool = {
      enable = mkEnableOption "session-tool";
      directories = mkOption {
        type = listOf str;
        default = ["$HOME"];
        description = "List of directories to select from when creating a session";
      };
      extraFdFlags = mkOption {
        type = listOf str;
        default = [];
        description = "Extra flags passed to fd";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."session-tool/session-tool.conf" = {
      text = ''
        directories=${lib.concatStringsSep ":" cfg.directories}
        fd_flags=${lib.concatStringsSep " " cfg.extraFdFlags}
      '';
    };
  };
}
