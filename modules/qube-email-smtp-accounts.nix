{ pkgs, ... }:

# Per-service send-only SMTP accounts on the qube.email mailserver. Each
# generator mints a random plaintext password (for the client service) and
# its bcrypt hash (for mailserver.loginAccounts.hashedPasswordFile). Shared
# so the mailserver machine and the consuming services agree on the secret.
let
  baseScript = ''
    PASSWORD=$(pwgen -s 32 -1 | tr -d '\n')
    HASH=$(printf '%s' "$PASSWORD" | mkpasswd -sm bcrypt)
    printf '%s' "$PASSWORD" > "$out"/password
    printf '%s' "$HASH" > "$out"/password-hash
  '';

  runtimeInputs = with pkgs; [
    coreutils
    mkpasswd
    pwgen
  ];
in
{
  clan.core.vars.generators = {
    qube-email-gitea-smtp = {
      share = true;
      files.password = { };
      files.password-hash = { };
      inherit runtimeInputs;
      script = baseScript;
    };

    qube-email-nextcloud-smtp = {
      share = true;
      files.password = { };
      files.password-hash = { };
      files.nextcloud-secrets-json = { };
      inherit runtimeInputs;
      script = baseScript + ''
        printf '{"mail_smtppassword":"%s"}' "$PASSWORD" > "$out"/nextcloud-secrets-json
      '';
    };
  };
}
