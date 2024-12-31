{config, pkgs, lib, ...}:

let
  porkbun_api_key = config.clan.dyndns.settings."gchq.icu".extraSettings.api_key;
  secret_dep_name = "dyndns-porkbun-gchq.icu";
in {

  clan.core.vars.generators.acme-porkbun-creds = 
  {
    share = true;
    files."acme-porkbun-creds" = {};
    dependencies = [
      secret_dep_name
    ];
    script = ''
      set -x
      dep_value=$(cat "$in/${secret_dep_name}/${secret_dep_name}")
      echo "PORKBUN_SECRET_API_KEY=\"$dep_value\"" > "$out/acme-porkbun-creds"
      echo "PORKBUN_API_KEY=\"${porkbun_api_key}\"" >> "$out/acme-porkbun-creds"
    '';
  };

  security.acme = {
    certs."gchq.icu" = {
      extraDomainNames = [ "*.gchq.icu" ];
      dnsProvider = "porkbun";
      dnsPropagationCheck = true;
      credentialsFile = config.clan.core.vars.generators.acme-porkbun-creds.files."acme-porkbun-creds".path;
      webroot = null;
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

}