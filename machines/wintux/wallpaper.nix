{ pkgs, ... }:

{
  systemd.user.services = {
    # Service to execute the script
    wallpaper = {
      path = with pkgs; [ dipc bash glib ];
      description = "Update Wallpaper Every 4 Hours";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ./wallpaper.sh;
      };
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
}
