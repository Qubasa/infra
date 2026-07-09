{ unstablePkgs, ... }:
let
  qubasa-blog = unstablePkgs.callPackage ../../pkgs/qubasa-blog/nix { };
in
{
  services.nginx = {
    virtualHosts = {
      "qubasa.blog" = {
        forceSSL = true;
        enableACME = true;
        root = "${qubasa-blog}";
        # Prerendered pages live at <route>/index.html; static assets
        # (/_app, /_pagefind, /feed.xml) are served directly.
        locations."/" = {
          tryFiles = "$uri $uri/index.html $uri.html =404";
        };
      };
    };
  };
}
