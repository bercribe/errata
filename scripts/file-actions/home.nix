{
  config,
  lib,
  ...
}: let
  cfg = config.programs.file-actions;
in {
  options = with lib;
  with types; {
    programs.file-actions = {
      enable = mkEnableOption "file-actions";
      actions = mkOption {
        type = listOf str;
        default = [];
        description = ''
          List of commands to offer as file actions.
          Use $f to specify where the file path should be inserted.
          If $f is not present, the file path is appended automatically.
        '';
        example = literalExpression ''
          [
            "cat"
            "vim $f"
            "cp $f /tmp/"
          ]
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."file-actions/actions" = {
      text = lib.concatStringsSep "\n" cfg.actions + "\n";
    };
  };
}
