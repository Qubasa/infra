{ lib, ... }:
{
  imports = [
    #clan-core.clanModules.sshd
    # clan-core.clanModules.root-password
  ];

  nix = {
    settings = {
      connect-timeout = lib.mkDefault 5;
      substituters = [
        "https://hetzner-cache.numtide.com"
        #"https://nixos.tvix.store"
      ];
    };
  };
}
