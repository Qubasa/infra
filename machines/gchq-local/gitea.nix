{ lib, config, ... }:

{
  # gitea-pre-start runs as the gitea user and reads the password via
  # `replace-secret`, so the deployed secret must be readable by gitea.
  clan.core.vars.generators.qube-email-gitea-smtp.files.password = {
    owner = "gitea";
    group = "gitea";
    restartUnits = [ "gitea.service" ];
  };

  clan.core.postgresql.users.gitea = { };
  clan.core.postgresql.databases.gitea.create.options = {
    TEMPLATE = "template0";
    LC_COLLATE = "C";
    LC_CTYPE = "C";
    ENCODING = "UTF8";
    OWNER = "gitea";
  };
  clan.core.postgresql.databases.gitea.restore.stopOnRestore = [ "gitea" ];

  clan.core.state.gitea = {
    folders = [ "/var/lib/gitea" ];
    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
        ]
      }

       systemctl stop gitea.service
    '';

    postBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
        ]
      }

      systemctl start gitea.service
    '';
  };

  services.gitea = {
    database.type = "postgres";
    settings = {
      session.COOKIE_SECURE = true;
      service.DISABLE_REGISTRATION = true;
      server = {
        # SSH_PORT = 7171;
        ROOT_URL = "https://gitea.gchq.icu";
        HTTP_ADDR = "localhost";
        DOMAIN = "gitea.gchq.icu";
        LEVEL = "Warn";
      };
      mailer = {
        ENABLED = true;
        PROTOCOL = "smtps";
        SMTP_ADDR = "qube.email";
        SMTP_PORT = 465;
        FROM = "Gitea <gitea-noreply@qube.email>";
        USER = "gitea-noreply@qube.email";
      };
      other = {
        SHOW_FOOTER_VERSION = false;
      };
    };
    mailerPasswordFile = config.clan.core.vars.generators.qube-email-gitea-smtp.files.password.path;
    enable = true;
  };

  services.nginx = {
    virtualHosts = {
      "gitea.gchq.icu" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://localhost:3000";
        };
      };
    };
  };

}
