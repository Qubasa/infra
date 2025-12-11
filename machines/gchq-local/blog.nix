{...}:
{

  users.users.blog = {
    isSystemUser = true;
    home = "/var/www/blog";
    createHome = true;
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
        locations."/" = {
          root = "/var/www/blog";
        };
      };
    };
  };
}