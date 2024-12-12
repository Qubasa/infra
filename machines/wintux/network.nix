{ config, lib, ... }:
{
  config = {
    networking.dhcpcd.enable = false;
    networking.nameservers = [ "127.0.0.1" ];
    networking.hostId = lib.mkDefault "8425e349";

    services.tailscale = {
      enable = true;
    };

    services.zerotierone.joinNetworks = [
      "9bee8941b53da940"
    ];
  };
}
