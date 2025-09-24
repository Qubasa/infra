# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, ... }:

{

  networking.interfaces.ens3.ipv6 = {
    addresses = [
      {
        address = "2a01:4f9:c010:51cd::2";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "ens3";
  };

  services.fail2ban = {
    enable = false;
    jails = {
      "dovecot2" = ''
        enabled = true
        filter = dovecot2
        action = iptables-multiport[name=dovecot2, port="pop3,imap", protocol=tcp]
        maxretry = 3
        findtime = 1200
        mode = aggressive
        bantime = 2d
      '';
    };
  };

  # Disable logging of scan services
  networking.firewall.logRefusedConnections = false;

  security.acme.defaults.email = "acme@qube.email";

  security.acme.acceptTerms = true;

  mailserver = {
    stateVersion = 3;
    enable = true;
    fqdn = "qube.email";
    domains = [ "qube.email" ];
    localDnsResolver = true;

    monitoring = {
      enable = true;
      alertAddress = "monitoring@qube.email";
    };

    # Generate password with:
    # mkpasswd -sm bcrypt
    loginAccounts = {
      "luis@qube.email" = {
        hashedPasswordFile = config.sops.secrets.qube-email-simplemail-luis-hash.path;
      };

      "noreply@qube.email" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets.qube-email-simplemail-noreply-hash.path;
      };

      "notrust@qube.email" = {
        # Can send emails back as every other user
        aliases = [
          "@qube.email"
        ];
        catchAll = [ "qube.email" ];
        hashedPasswordFile = config.sops.secrets.qube-email-simplemail-notrust-hash.path;
      };

    };

    # debug = false;

    certificateScheme = "acme-nginx";
    dkimSelector = "mail";
    dkimSigning = true;
    enableImap = true;
    enablePop3 = true;
    enableImapSsl = true;
    enablePop3Ssl = true;

    enableManageSieve = true;

    virusScanning = false;
  };

  system.autoUpgrade.allowReboot = true;

  systemd.watchdog.runtimeTime = "5m";
  systemd.watchdog.rebootTime = "15m";

  networking.firewall.allowedTCPPorts = [
    7171
    80
    443
  ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

  # 2. Add extra configuration directly to Postfix.
  # services.postfix.extraConfig =
  #   let
  #     submissionChecksFile = pkgs.writeText "submission_header_checks" ''
  #       # This regular expression matches any "Received:" header and tells Postfix to IGNORE (delete) it.
  #       /^Received: .*/ IGNORE
  #     '';
  #   in
  #   ''
  #     # Apply header checks only to mail coming through the submission service.
  #     submission_header_checks = regexp:${submissionChecksFile}
  #   '';
}
