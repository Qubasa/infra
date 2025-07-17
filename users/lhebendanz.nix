{ pkgs, ... }:
{
  users.users."lhebendanz".shell = pkgs.zsh;
  services.displayManager.autoLogin.user = "lhebendanz";
  nix.settings.trusted-users = [ "lhebendanz" ];
}
