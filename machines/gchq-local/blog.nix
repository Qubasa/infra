{ ... }:
{

  users.users.blog = {
    isSystemUser = true;
    home = "/var/www/blog";
    createHome = true;
    homeMode = "750";
    description = "Blog user";
    group = "blog";
  };

  users.users.nginx.extraGroups = [ "blog" ];
  users.groups.blog = { };

  services.nginx = {
    virtualHosts = {
      "qubasa.blog" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/blog";
        locations."/assets" = { };
        locations."/" = {
          tryFiles = "/index.html =404";
        };
      };
    };
  };
}
