{ pkgs, config, lib, ... }:

let

  cfg = config.programs.wallpaper;
  postProcessFlag = if cfg.postProcessing.enable then "true" else "false"; 
in {

  options.programs.wallpaper = {
    lightWallDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to a directory with light Wallpapers";
    };
    darkWallDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to a directory with dark Wallpapers";
    };
    postProcessing = {
      enable = lib.mkEnableOption "turn on a color filter effect";
      dark = lib.mkOption {
        type = lib.types.str;
        default = "darcula";
      };
      light = lib.mkOption {
        type = lib.types.str;
        default = "solarized";
      };
    };
  };

  config = {
    systemd.user.services = {
      # Service to execute the script
      wallpaper = {
        path = with pkgs; [ dipc bash glib ];
        description = "Update Wallpaper Every 4 Hours";
        environment = {
          LIGHT_PALETTE=cfg.postProcessing.light;
          DARK_PALETTE=cfg.postProcessing.dark;
        };
        script = ''
          ${./wallpaper.sh} "${cfg.darkWallDir}" "${cfg.lightWallDir}" "${postProcessFlag}"
        '';
        wantedBy = [ "default.target" ];
      };
    };
    systemd.user.timers = {
      # Timer to schedule the execution every 4 hours
      wallpaper-timer = {
        description = "Timer to update wallpaper every 4 hours";
        timerConfig = {
          OnCalendar = "*-*-* *:0/4:00";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };
    };
  };
}
