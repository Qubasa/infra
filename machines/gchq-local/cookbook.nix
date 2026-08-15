{ pkgs, ... }:
{
  imports = [ ../../modules/nginx ];

  # `just deploy` from ~/Projects/berlin_cooking_recepies rsyncs the rendered
  # static site into this directory. Nothing here knows about that repo.
  environment.systemPackages = [ pkgs.rsync ];
  systemd.tmpfiles.rules = [ "d /var/www/cook 0755 root root -" ];

  # Anubis in subrequest-auth mode, same shape as the gitea instance.
  # 3001 is taken by anubis-gitea, so this one gets 3002.
  services.anubis.instances.cookbook = {
    settings = {
      # https://anubis.techaro.lol/docs/admin/configuration/subrequest-auth
      TARGET = " ";
      BIND = "127.0.0.1:3002";
      BIND_NETWORK = "tcp";
      OG_PASSTHROUGH = true;
      REDIRECT_DOMAINS = "cook.gchq.icu";
    };

    policy.settings.status_codes = {
      CHALLENGE = 200;
      DENY = 403;
    };
  };

  services.nginx.virtualHosts."cook.gchq.icu" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/cook";

    locations."/" = {
      tryFiles = "$uri $uri/index.html =404";
      extraConfig = ''
        auth_request /.within.website/x/cmd/anubis/api/check;
        error_page 401 = @redirectToAnubis;
      '';
    };

    # The challenge endpoint must never be challenged.
    locations."/.within.website/" = {
      proxyPass = "http://127.0.0.1:3002";
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

    # Assets are only fetched after a page that already passed the challenge,
    # so a subrequest per font and stylesheet buys nothing.
    locations."/static/".extraConfig = "auth_request off;";

    locations."= /robots.txt".extraConfig = ''
      auth_request off;
      add_header Content-Type text/plain;
      return 200 "User-agent: *\nDisallow: /\n";
    '';
  };
}
