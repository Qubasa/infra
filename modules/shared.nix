{ lib, ... }:
{
  imports = [
    ./nixpkgs-unfree.nix
    #clan-core.clanModules.sshd
    # clan-core.clanModules.root-password
  ];

  nix = {
    settings = {
      download-attempts = 1;
      connect-timeout = lib.mkForce 2;
      substituters = [
        "https://hetzner-cache.numtide.com"
        "https://cache.geninf.io"
        # "https://nixos.tvix.store"
      ];
      trusted-public-keys = [
        "cache.geninf.io-1:uhEViaczNKSoerYM+w7uqXUzlAhnbEBKsFzgg9n3cvI="
      ];
    };
  };
}
