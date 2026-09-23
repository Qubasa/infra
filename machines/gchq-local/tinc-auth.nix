{
  config,
  lib,
  pkgs,
  ...
}:
let
  net = config.services.tincr.networks.tincr;
  meshIp = builtins.head (lib.splitString "/" (builtins.head net.addresses));
  issuer = "http://gchq-local.tincr:8443";
  gitea = config.services.gitea;
  secret = config.clan.core.vars.generators.tinc-auth-gitea.files.secret;

  clientsJson = pkgs.writeShellScript "tinc-auth-clients" ''
    ${lib.getExe pkgs.jq} -n \
      --rawfile secret "$CREDENTIALS_DIRECTORY/gitea-secret" \
      --arg uri ${lib.escapeShellArg "${gitea.settings.server.ROOT_URL}/user/oauth2/tinc/callback"} \
      '[{ id: "gitea", secret: $secret, redirect_uris: [ $uri ] }]' \
      > "$RUNTIME_DIRECTORY/clients.json"
  '';
in
{
  clan.core.vars.generators.tinc-auth-gitea = {
    files.secret = {
      owner = gitea.user;
      group = gitea.group;
      restartUnits = [
        "tinc-auth.service"
        "gitea-tinc-oauth.service"
      ];
    };
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssl
    ];
    script = ''
      openssl rand -hex 32 | tr -d '\n' > "$out/secret"
    '';
  };

  # tinc-auth insists on a listen socket even when only the OIDC provider is used.
  systemd.sockets.tinc-auth = {
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "/run/tinc-auth.sock" ];
    socketConfig.SocketMode = "0600";
  };

  systemd.services.tinc-auth = {
    description = "tinc-auth OpenID Connect provider for the tincr mesh";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "tinc-auth.socket"
      "tincr-tincr.service"
    ];
    after = [
      "tinc-auth.socket"
      "tincr-tincr.service"
    ];
    serviceConfig = {
      User = "tincr";
      Group = "tincr";
      LoadCredential = [ "gitea-secret:${secret.path}" ];
      RuntimeDirectory = "tinc-auth";
      StateDirectory = "tinc-auth/idp";
      StateDirectoryMode = "0700";
      ExecStartPre = clientsJson;
      ExecStart = lib.concatStringsSep " " [
        "${net.package}/bin/tinc-auth -n tincr --pidfile /run/tincr/tincr.pid"
        "--idp-listen [${meshIp}]:8443 --issuer ${issuer}"
        "--clients /run/tinc-auth/clients.json --email-domain tincr.invalid"
      ];
      # The mesh address appears only once tincd is up.
      Restart = "on-failure";
      RestartSec = 2;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  # tinc-auth keeps its OIDC signing key in CONFDIR/idp, and /etc is read-only.
  systemd.tmpfiles.rules = [ "L /etc/tinc/tincr/idp - - - - /var/lib/tinc-auth/idp" ];

  networking.firewall.interfaces.${net.interfaceName}.allowedTCPPorts = [ 8443 ];

  # Registration stays disabled, so a mesh login must be linked to an existing account once.
  systemd.services.gitea-tinc-oauth = {
    description = "Register tinc-auth as Gitea login source";
    wantedBy = [ "multi-user.target" ];
    requires = [ "gitea.service" ];
    wants = [ "tinc-auth.service" ];
    after = [
      "gitea.service"
      "tinc-auth.service"
    ];
    path = [ pkgs.gawk ];
    environment = {
      GITEA_WORK_DIR = gitea.stateDir;
      GITEA_CUSTOM = gitea.customDir;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = gitea.user;
      Group = gitea.group;
      WorkingDirectory = gitea.stateDir;
      Restart = "on-failure";
      RestartSec = 5;
    };
    script = ''
      auth() { ${lib.getExe gitea.package} --config ${gitea.customDir}/conf/app.ini admin auth "$@"; }
      secret=$(< ${secret.path})
      discovery=${issuer}/.well-known/openid-configuration
      id=$(auth list | awk '$2 == "tinc" { print $1 }')
      if [ -n "$id" ]; then
        auth update-oauth --id "$id" --secret "$secret" --auto-discover-url "$discovery"
      else
        auth add-oauth --name tinc --provider openidConnect --key gitea \
          --secret "$secret" --auto-discover-url "$discovery"
      fi
    '';
  };
}
