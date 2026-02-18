{ pkgs, ... }:

{
  services.postgresql = {
    package = pkgs.postgresql_18;
  };

  networking.fqdn = "qube.email";
}
