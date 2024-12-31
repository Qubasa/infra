{config, lib, ...}:

let
  cfg = config.clan.porkbun-wildcard-certs;
in {
  options.clan.porkbun-wildcard-certs = {
    porkbun_api_key = lib.mkOption {
      type = lib.types.string;
      description = "Porkbun API key";
    };
    porkbun_secret_generator = lib.mkOption {
      type = lib.types.string;
      description = "Generator name for the Porkbun API key secret";
    };
  };

  config = {
    clan.core.vars.generators.acme-porkbun-creds = 
    {
      share = true;
      files."acme-porkbun-creds" = {};
      dependencies = [
        cfg.porkbun_secret_generator
      ];
      script = ''
        set -x
        dep_value=$(cat "$in/${cfg.porkbun_secret_generator}/${cfg.porkbun_secret_generator}")
        echo "PORKBUN_SECRET_API_KEY=\"$dep_value\"" > "$out/acme-porkbun-creds"
        echo "PORKBUN_API_KEY=\"${cfg.porkbun_api_key}\"" >> "$out/acme-porkbun-creds"
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
  };
}