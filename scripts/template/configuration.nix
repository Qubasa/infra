{
  clan-core,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    clan-core.clanModules.trusted-nix-caches
    clan-core.clanModules.zerotier-static-peers
    clan-core.clanModules.machine-id
    clan-core.clanModules.iwd
    # # === Demo 1 === ##
    # clan-core.clanModules.dyndns
    # # === Demo 2 === ##
    # inputs.data-mesher.nixosModules.data-mesher
    # # === Demo 3 === ##
    # clan-core.clanModules.matrix-synapse
  ];

  clan.iwd.networks = {
    "testnet" = {
      AutoConnect = true;
    };
  };

  disko.devices.disk.main.device = "/dev/sda";

  # Set this for clan commands use ssh i.e. `clan machines update`
  # clan.core.networking.targetHost = pkgs.lib.mkDefault "root@157.90.21.116";

  ## === Demo 1 === ##
  # clan.dyndns = {
  #     server = {
  #       enable = true;
  #       domain = "demo.gchq.icu";
  #     };
  #     settings = {
  #     "demo.gchq.icu" = {
  #         provider = "namecheap";
  #         domain = "gchq.icu";
  #         extraSettings = {
  #           host = "demo";
  #         };
  #     };
  #     "matrix.demo.gchq.icu" = {
  #         provider = "namecheap";
  #         domain = "gchq.icu";
  #         extraSettings = {
  #           host = "matrix.demo";
  #         };
  #     };
  #   };
  # };

  ## === Demo 2 === ##
  # networking.domain = "dark";
  # services.data-mesher = {
  #   enable = true;
  #   logLevel  = "DEBUG";
  #   interface = "ztzvcqjigy";
  #   openFirewall = true;
  #   bootstrapPeers = [ "http://[fd16:aa77:dbef:737b:3799:9316:aa77:dbef]:7331" ];
  # };

  ## === Demo 3 === ##
  # clan.matrix-synapse = {
  #   server_tld = "demo.gchq.icu";
  #   app_domain = "matrix.demo.gchq.icu";

  #   users = {
  #     "Demo" = {
  #       admin = true;
  #     };
  #   };
  # };

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
    ripgrep
  ];

  # IMPORTANT! Add your SSH key here
  # e.g. > cat ~/.ssh/id_ed25519.pub
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB0d0JA20Vqn7I4lCte6Ne2EOmLZyMJyS9yIKJYXNLjbLwkQ4AYoQKantPBkTxR75M09E7d3j5heuWnCjWH45TrfQfe1EOSSC3ppCI6C6aIVlaNs+KhAYZS0m2Y8WkKn+TT5JLEa8yybYVN/RlZPOilpj/1QgjU6CQK+eJ1k/kK+QFXcwN82GDVh5kbTVcKUNp2tiyxFA+z9LY0xFDg/JHif2ROpjJVLQBJ+YPuOXZN5LDnVcuyLWKThjxy5srQ8iDjoxBg7dwLHjby5Mv41K4W61Gq6xM53gDEgfXk4cQhJnmx7jA/pUnsn2ZQDeww3hcc7vRf8soogXXz2KC9maiq0M/svaATsa9Ul4hrKnqPZP9Q8ScSEAUX+VI+x54iWrnW0p/yqBiRAzwsczdPzaQroUFTBxrq8R/n5TFdSHRMX7fYNOeVMjhfNca/gtfw9dYBVquCvuqUuFiRc0I7yK44rrMjjVQRcAbw6F8O7+04qWCmaJ8MPlmApwu2c05VMv9hiJo5p6PnzterRSLCqF6rIdhSnuOwrUIt1s/V+EEZXHCwSaNLaQJnYL0H9YjaIuGz4c8kVzxw4c0B6nl+hqW5y5/B2cuHiumnlRIDKOIzlv8ufhh21iN7QpIsPizahPezGoT1XqvzeXfH4qryo8O4yTN/PWoA+f7o9POU7L6hQ== lhebendanz@nixos"
  ];

  clan.core.deployment.requireExplicitUpdate = true;
}
