{
  config,
  lib,
  ...
}: let
  cfg = config.programs.snippets;
in {
  options = with lib;
  with types; {
    programs.snippets = {
      enable = mkEnableOption "snippets";
      snippets = mkOption {
        type = attrsOf str;
        default = {};
        description = "Attrset of snippet names to text content. Each entry creates a file at ~/.config/snippets/<name>";
        example = literalExpression ''
          {
            email = "user@example.com";
            address = "123 Main St";
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = with lib;
      mapAttrs' (
        name: value:
          nameValuePair "snippets/${name}" {text = value;}
      )
      cfg.snippets;
  };
}
