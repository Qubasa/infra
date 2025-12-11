{
  config,
  pkgs,
  lib,
  ...
}:

{

  services.open-webui = {
    enable = true;
    port = 2712;
  };

  networking.hosts = {
    "127.0.0.1" = [
      "openwebui.local"
      "kimai.local"
    ];
  };

  clan.core.vars.generators."kimai" = {
    files.db-password = { };
    runtimeInputs = [
      pkgs.pwgen
    ];
    script = ''
      pwgen -s 16 1 > $out/db-password
    '';
  };

  #### KIMAI ####
  users.users.kimai = {
    isSystemUser = lib.mkForce false;
    isNormalUser = true;
    group = lib.mkForce "kimai";
    createHome = lib.mkForce false;
  };
  users.groups.kimai = { };
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "kimai" ];
    settings = {
      mysqld = {
        bind-address = "localhost";
      };
    };
    ensureUsers = [
      {
        name = "kimai";
        ensurePermissions = {
          "kimai.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # clan.core.state."kimai" = {
  #   folders = [
  #     "/var/lib/kimai"
  #   ];
  #   preBackupScript = ''
  #     export PATH=${
  #       lib.makeBinPath [
  #         config.systemd.package
  #       ]
  #     }

  #      systemctl stop kimai-init-kimai.local.service
  #   '';
  #   postBackupScript = ''
  #     export PATH=${
  #       lib.makeBinPath [
  #         config.systemd.package
  #       ]
  #     }

  #     systemctl start kimai-init-kimai.local.service
  #   '';
  # };

  services.kimai.sites."kimai.local" = {
    database = {
      createLocally = false;
      serverVersion = "10.11.14-MariaDB";
      user = "kimai";
      passwordFile = config.clan.core.vars.generators."kimai".files.db-password.path;
    };
  };
  #### END KIMAI ####

  services.nginx = {
    enable = true;
    defaultListen = [
      {
        addr = "localhost";
        ssl = false;
      }
    ];
    virtualHosts = {
      "openwebui.local" = {
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://localhost:2712";
        };
      };
    };
  };
}
