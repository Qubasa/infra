{
  config,
  clan-core,
  pkgs,
  ...
}:

let
  username = "admin";
in
{
  system.stateVersion = "24.11";

  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./network.nix
    ./initrd.nix
    ./gitea.nix
    ./nextcloud.nix
    #./home-assistant.nix
    ../../modules/backups.nix
    ../../modules/porkbun-wildcard-certs.nix
    clan-core.clanModules.user-password
    clan-core.clanModules.dyndns
    clan-core.clanModules.matrix-synapse
    clan-core.clanModules.vaultwarden
    clan-core.clanModules.heisenbridge
    clan-core.clanModules.trusted-nix-caches
    clan-core.clanModules.zerotier-static-peers
  ];

  networking.domain = "dark";

  clan.nginx.acme.email = "acme@qube.email";

  nix = {
    gc.automatic = true;
    gc.dates = "daily";
    gc.options = "--delete-older-than 30d";
  };

  # nixpkgs.config = {
  #   permittedInsecurePackages = [
  #     "olm-3.2.16"
  #   ];
  #   allowUnfree = true;
  # };

  # Disable deep sleep on lid close
  services.logind = {
    lidSwitch = "ignore";
    powerKey = "ignore";
    suspendKey = "ignore";
    hibernateKey = "ignore";
    suspendKeyLongPress = "ignore";
    powerKeyLongPress = "poweroff";
  };
  # Disable display after 60s of inactivity
  boot.kernelParams = [ "consoleblank=60" ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
  };

  clan.vaultwarden = {
    domain = "bitwarden.gchq.icu";
    smtp = {
      username = "noreply@qube.email";
      from = "noreply@qube.email";
      host = "qube.email";
    };
  };

  clan.matrix-synapse = {

    server_tld = "gchq.icu";
    app_domain = "element.gchq.icu";

    users = {
      "Qubasa" = {
        admin = true;
      };
    };
  };

  clan.dyndns =
    let
      generateConfig = host: {
        provider = "porkbun";
        domain = "gchq.icu";
        secret_field_name = "secret_api_key";
        extraSettings = {
          host = host;
          ip_version = "ipv4";
          ipv6_suffix = "";
          # This is a pubkey. It is not a secret.
          api_key = "pk1_49dcc3b4df71eaebe608d951aac06a13c23d932e3564b577c1232e5a257e2973";
        };
      };
    in
    {
      server = {
        enable = true;
        domain = "home.gchq.icu";
      };
      settings = {
        "gchq.icu" = generateConfig "@";
        "home.gchq.icu" = generateConfig "home";
        "gitea.gchq.icu" = generateConfig "gitea";
        "element.gchq.icu" = generateConfig "element";
        "bitwarden.gchq.icu" = generateConfig "bitwarden";
        "cloud.gchq.icu" = generateConfig "cloud";
      };
    };

  clan.porkbun-wildcard-certs = {
    porkbun_api_key = config.clan.dyndns.settings."gchq.icu".extraSettings.api_key;
    porkbun_secret_generator = "dyndns-porkbun-gchq.icu";
  };

  # Automatically set timezone
  time.timeZone = null;

  # Set keyboard layout
  console.keyMap = "de";

  # Select internationalisation properties  .
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    # Add packages you want to install here
    # e.g. vim
    helix
    git
    fd
    tmux
    ripgrep
  ];

  clan.user-password.user = username;

  # Set this for clan commands use ssh i.e. `clan machines update`
  clan.core.networking.targetHost = pkgs.lib.mkDefault "root@home.gchq.icu";

  # IMPORTANT! Add your SSH key here
  # e.g. > cat ~/.ssh/id_ed25519.pub
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB0d0JA20Vqn7I4lCte6Ne2EOmLZyMJyS9yIKJYXNLjbLwkQ4AYoQKantPBkTxR75M09E7d3j5heuWnCjWH45TrfQfe1EOSSC3ppCI6C6aIVlaNs+KhAYZS0m2Y8WkKn+TT5JLEa8yybYVN/RlZPOilpj/1QgjU6CQK+eJ1k/kK+QFXcwN82GDVh5kbTVcKUNp2tiyxFA+z9LY0xFDg/JHif2ROpjJVLQBJ+YPuOXZN5LDnVcuyLWKThjxy5srQ8iDjoxBg7dwLHjby5Mv41K4W61Gq6xM53gDEgfXk4cQhJnmx7jA/pUnsn2ZQDeww3hcc7vRf8soogXXz2KC9maiq0M/svaATsa9Ul4hrKnqPZP9Q8ScSEAUX+VI+x54iWrnW0p/yqBiRAzwsczdPzaQroUFTBxrq8R/n5TFdSHRMX7fYNOeVMjhfNca/gtfw9dYBVquCvuqUuFiRc0I7yK44rrMjjVQRcAbw6F8O7+04qWCmaJ8MPlmApwu2c05VMv9hiJo5p6PnzterRSLCqF6rIdhSnuOwrUIt1s/V+EEZXHCwSaNLaQJnYL0H9YjaIuGz4c8kVzxw4c0B6nl+hqW5y5/B2cuHiumnlRIDKOIzlv8ufhh21iN7QpIsPizahPezGoT1XqvzeXfH4qryo8O4yTN/PWoA+f7o9POU7L6hQ== lhebendanz@nixos"
  ];

  # Zerotier needs one controller to accept new nodes. Once accepted
  # the controller can be offline and routing still works.
  clan.core.networking.zerotier.controller.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "dialout"
      "disk"
    ];
    uid = 1000;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };
}
