{ config, lib, ... }:
{
  config = {
    networking.dhcpcd.enable = false;
    networking.nameservers = [ "127.0.0.1" ];
    networking.hostId = "a80ebdda"; # Needs to be unique for each host
  };
}
