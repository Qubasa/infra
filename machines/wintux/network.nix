{ lib, ... }:
{
  config = {
    networking.dhcpcd.enable = false;
    networking.nameservers = [ "127.0.0.1" ];
    networking.hostId = lib.mkDefault "8425e349";
    services.resolved = {
      enable = true;
    };

    services.tailscale = {
      enable = true;
    };

    services.zerotierone.joinNetworks = [
      "a9b4872919354736" # storinator01
      "8cf9e05d03205934" # test-clan: jon
    ];

  };
}
