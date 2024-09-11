{ config, lib, ... }:
{
  config = {
    networking.dhcpcd.enable = false;
    networking.nameservers = [ "127.0.0.1" ];
    networking.hostId = lib.mkDefault "8425e349";
  };
}
