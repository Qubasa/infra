{ config, pkgs, ... }:

rec {

  # IMPORTANT: To upgrade nextcloud
  # make sure to set enable to false
  # and then change the nextcloud package version!
  services.nextcloud = {
    enable = true;
    https = true;
    hostName = "cloud.gchq.icu";
    phpOptions = {
      "opcache.interned_strings_buffer" = "23";
    };
    package = pkgs.nextcloud30;
    settings = {
      default_phone_region = "DE";
      # TODO: systemd backend needs a packaged https://github.com/systemd/php-systemd which doesn't exist yet
      log_type = "file";
    };
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
      dbname = "nextcloud";
      adminpassFile = "/var/lib/nextcloud/nextcloud_admin.txt";
      adminuser = "Luis";
    };
  };

  # TODO: systemd backend needs a packaged https://github.com/systemd/php-systemd which doesn't exist yet
  # services.nextcloud.phpExtraExtensions = [

  # ];

  # security hardening
  systemd.services."phpfpm-nextcloud" = {
    serviceConfig = {
      NoNewPrivileges = "yes";
    };
  };

  # Note: The occ commands is called nextcloud-occ
  # The nextcloud service is called phpfpm-nextcloud.service

  # Note: All nextcloud data is stored at /var/lib/nextcloud
  # if you have to do a fresh install backup the data folder
  # and delete everything else

  # Note: To delete an old table
  # login to the postgres user
  # $ su postgres
  # $ psql
  # $ DROP DATABASE nextcloud;
  # Afterwards disable and enable postgresql
  # to ensure the nextcloud table is created
  clan.postgresql.databases.nextcloud.create.options = {
    TEMPLATE = "template0";
    LC_COLLATE = "C";
    LC_CTYPE = "C";
    ENCODING = "UTF8";
    OWNER = "nextcloud";
  };
  clan.postgresql.databases.nextcloud.restore.stopOnRestore = [ "phpfpm-nextcloud" ];

  services.nginx.virtualHosts.${services.nextcloud.hostName} = {
    enableACME = true;
    onlySSL = true;
    extraConfig = '''';
  };
}
