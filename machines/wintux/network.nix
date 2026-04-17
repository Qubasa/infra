{ config, lib, ... }:
{
  config = {
    networking.dhcpcd.enable = false;
    networking.nameservers = [ "127.0.0.1" ];
    # Allow harmonia to function properly
    networking.firewall.allowedTCPPorts = [ 5000 ];
    networking.hostId = lib.mkDefault "8425e349";
    services.resolved = {
      enable = true;
    };

    services.tailscale = {
      enable = true;
    };

    services.zerotierone.joinNetworks = [
      "a9b4872919354736" # storinator01
    ];

    clan.core.state."tailscale" = {
      folders = [
        "/var/lib/tailscale"
      ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            config.systemd.package
          ]
        }

         systemctl stop tailscaled.service
      '';
      postBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            config.systemd.package
          ]
        }

        systemctl start tailscaled.service
      '';
    };

    clan.core.state."network-manager" = {
      folders = [
        "/etc/NetworkManager"
      ];
    };
  };
}
