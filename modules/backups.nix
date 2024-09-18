{
  lib,
  config,
  pkgs,
  ...
}:
{
  services.zfs = lib.mkIf (config.boot.zfs.enabled) {
    autoSnapshot.enable = true;
    # defaults to 12, which is a bit much given how much data is written
    autoSnapshot.monthly = lib.mkDefault 1;
    autoScrub.enable = true;
  };

  environment.systemPackages = [
    pkgs.httm
  ];
}
