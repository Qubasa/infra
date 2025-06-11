{ pkgs, config, ... }:
{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = config.clan.user-password.user;
  services.xserver.xkb.layout = "de";
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnome-pomodoro
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.tactile
    dipc
    gnome-tweaks
    dconf-editor
  ];
}
