{config, lib, pkgs, ...}:

{

  networking.firewall.allowedUDPPorts = [ config.services.iperf3.port ];


  services.iperf3 = {
    enable = true;
    openFirewall = true;
    rsaPrivateKey = ./iperf3.private;
    authorizedUsersFile = ./iperf3.pwd;
  };
}
