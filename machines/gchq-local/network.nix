{ config, ... }:
{
  config = {
    networking.dhcpcd.enable = false;
    networking.nameservers = [ "127.0.0.1" ];
    networking.hostId = "a70ebcca"; # Needs to be unique for each host
  };
}
