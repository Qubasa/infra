{ lib, clan-core, ... }:
{
  imports = [
    clan-core.clanModules.sshd
    clan-core.clanModules.root-password
  ];

  nix = {
    settings = {
      connect-timeout = lib.mkDefault 5;
      substituters = [
        "https://nixos.tvix.store"
      ];
    };
  };
}
