{ lib, ... }:
{
  imports = [
    #clan-core.clanModules.sshd
    # clan-core.clanModules.root-password
  ];

  nix = {
    settings = {
      download-attempts = 1;
      connect-timeout = lib.mkForce 2;
      substituters = [
        "https://hetzner-cache.numtide.com"
        "https://nixos.tvix.store"
      ];
    };
  };
}
