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

  services.anubis.instances.gitea = {
    settings = {
      # https://anubis.techaro.lol/docs/admin/configuration/subrequest-auth
      TARGET = " ";
      BIND = "127.0.0.1:3001";
      BIND_NETWORK = "tcp";
      OG_PASSTHROUGH = true;
      # Just in case we ever stop using subrequest auth
      # https://anubis.techaro.lol/docs/admin/configuration/redirect-domains
      REDIRECT_DOMAINS = config.services.gitea.settings.server.DOMAIN;
    };

    policy = {
      # https://anubis.techaro.lol/docs/admin/configuration/subrequest-auth
      settings.status_codes = {
        CHALLENGE = 200;
        DENY = 403;
      };

      # https://github.com/TecharoHQ/anubis/blob/main/data/apps/gitea-rss-feeds.yaml
      extraBots = [
        { import = "(data)/apps/gitea-rss-feeds.yaml"; }
      ];
    };
  };

  services.nginx = {
    virtualHosts = {
      "gitea.gchq.icu" = {
        forceSSL = true;
        enableACME = true;

        # https://anubis.techaro.lol/docs/admin/configuration/subrequest-auth
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://localhost:3000";
          extraConfig = ''
            auth_request /.within.website/x/cmd/anubis/api/check;
            error_page 401 = @redirectToAnubis;
          '';
        };

        locations."/.within.website/" = {
          proxyPass = "http://127.0.0.1:3001";
          extraConfig = ''
            auth_request off;
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
          '';
        };

        locations."@redirectToAnubis".extraConfig = ''
          return 307 /.within.website/?redir=$scheme://$host$request_uri;
          auth_request off;
        '';

        locations."= /robots.txt".alias = ./robots.txt;
      };
    };
  };

}
