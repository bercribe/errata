{
  config,
  lib,
  ...
}: let
  cfg = config.programs.sfx;
in {
  options = with lib;
  with types; {
    programs.sfx = {
      enable = mkEnableOption "sfx";
      sounds = mkOption {
        type = attrsOf path;
        default = {};
        description = "Attrset of sound effect names to .mp3 file paths. Each entry creates a file at ~/.config/sfx/<name>.mp3";
        example = literalExpression ''
          {
            ding = ./sounds/ding.mp3;
            buzz = ./sounds/buzz.mp3;
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = with lib;
      mapAttrs' (
        name: path:
          nameValuePair "sfx/${name}.mp3" {source = path;}
      )
      cfg.sounds;
  };
}
