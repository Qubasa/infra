{ ... }:

{

  clan.postgresql.users.gitea = { };
  clan.postgresql.databases.gitea.create.options = {
    TEMPLATE = "template0";
    LC_COLLATE = "C";
    LC_CTYPE = "C";
    ENCODING = "UTF8";
    OWNER = "gitea";
  };
  clan.postgresql.databases.gitea.restore.stopOnRestore = [ "gitea" ];

  services.gitea = {
    database.type = "postgres";
    settings = {
      session.COOKIE_SECURE = true;
      service.DISABLE_REGISTRATION = true;
      server = {
        SSH_PORT = 7171;
        ROOT_URL = "https://gitea.gchq.icu";
        HTTP_ADDR = "localhost";
        DOMAIN = "gitea.gchq.icu";
        LEVEL = "Warn";
      };
      # mailer = {
      #   ENABLED = true;
      #   MAILER_TYPE = "smtps";
      #   FROM = "noreply@qube.email";
      # };
      other = {
        SHOW_FOOTER_VERSION = false;
      };
    };
    # mailerPasswordFile = config.sops.secrets.gchq-local-gitea-smtp.path;
    enable = true;
    useWizard = false;
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
