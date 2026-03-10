{ ... }:
{
  _class = "clan.service";
  manifest.name = "sable";
  manifest.description = "Sable Matrix web client served via nginx";
  manifest.categories = [ "Social" ];

  roles.server = {
    description = "Sable web client served behind nginx";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            example = "element.example.com";
            description = "Domain name to serve Sable on.";
          };

          homeserverList = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "matrix.org" ];
            description = "List of Matrix homeservers to offer in the login UI.";
          };

          defaultHomeserver = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Index into homeserverList for the default homeserver.";
          };

          allowCustomHomeservers = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether users can enter a custom homeserver URL.";
          };

          enableACME = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to enable ACME (Let's Encrypt) for the domain.";
          };

          acmeEmail = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Email address for ACME certificate notifications.";
          };

          extraConfig = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = ''
              Extra attributes merged into config.json.
              See https://github.com/SableClient/Sable/blob/main/config.json
            '';
          };
        };
      };

    perInstance =
      { settings, ... }:
      {
        nixosModule =
          {
            lib,
            pkgs,
            ...
          }:
          let
            cfg = settings;

            sources = import ../../pkgs/sable/_sources/generated.nix {
              inherit (pkgs) fetchurl fetchgit fetchFromGitHub dockerTools;
            };

            sable = pkgs.callPackage ../../pkgs/sable/package.nix { inherit sources; };

            configJson = pkgs.writeText "config.json" (
              builtins.toJSON (
                lib.recursiveUpdate {
                  inherit (cfg) defaultHomeserver homeserverList allowCustomHomeservers;
                  hashRouter = {
                    enabled = false;
                    basename = "/";
                  };
                  slidingSync.enabled = true;
                } cfg.extraConfig
              )
            );

            webroot = pkgs.runCommand "sable-webroot" { } ''
              cp -r ${sable} $out
              chmod -R u+w $out
              cp ${configJson} $out/config.json
            '';
          in
          {
            services.nginx = {
              enable = true;
              virtualHosts.${cfg.domain} = {
                forceSSL = cfg.enableACME;
                enableACME = cfg.enableACME;
                root = webroot;
                locations."/" = {
                  tryFiles = "$uri $uri/ /index.html";
                  extraConfig = ''
                    gzip on;
                    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
                  '';
                };
              };
            };

            security.acme = lib.mkIf cfg.enableACME {
              acceptTerms = true;
              defaults.email = cfg.acmeEmail;
            };
          };
      };
  };
}
