{ config, ... }:
{
  networking.useNetworkd = true;
  networking.useDHCP = false;

  systemd.network.networks."10-uplink" = {
    matchConfig.Name = "enp0s31f6";
    address = [
      "136.243.172.251/26"
      "2a01:4f8:171:21d5::1/64"
    ];
    routes = [
      { routeConfig.Gateway = "136.243.172.193"; }
      { routeConfig.Gateway = "fe80::1"; }
    ];
    networkConfig.IPv6AcceptRA = false;
  };

  # Share network config with initrd for SSH unlock during boot
  boot.initrd.systemd.network.networks."10-uplink" = config.systemd.network.networks."10-uplink";
}
