{ pkgs, config, ... }:
{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = config.clan.user-password.user;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
