{ pkgs, ... }:
{
  users.users."lhebendanz".shell = pkgs.zsh;
  nix.settings.trusted-users = [ "lhebendanz" ];

  clan.core.state."user-lhebendanz" = {
    folders = [
      "/home/lhebendanz"
    ];
  };
}
