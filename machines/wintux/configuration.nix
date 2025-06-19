{
  flakeInputs,
  clan-core,
  pkgs,
  config,
  ...
}:

{
  imports = [
    clan-core.clanModules.trusted-nix-caches
    clan-core.clanModules.user-password
    clan-core.clanModules.iwd
    flakeInputs.chrome-pwa.nixosModule
    flakeInputs.nix-index-database.nixosModules.nix-index
    ../../modules/backups.nix
    ../../modules/wallpaper
    ../../modules/latest-zfs-kernel.nix
    ./vscode.nix
    ./webapps.nix
    # ./kernel.nix
    ./disko.nix
    ./initrd.nix
    ./network.nix
    ./packages.nix
    ./zsh.nix
    ./display.nix
    ./radeon.nix
    ./mitm.nix
    # ./nvidia.nix
  ];

  clan.user-password.user = "lhebendanz";

  programs.wallpaper = {
    darkWallDir = "$HOME/Pictures/Wallpapers/dark";
    lightWallDir = "$HOME/Pictures/Wallpapers/light";
  };

  nix = {
    package = pkgs.nixVersions.latest;
  };

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "vscode";
  };

  virtualisation.libvirtd.enable = true;

  services.chrome-pwa.enable = true;

  users.users."${config.clan.user-password.user}" = {
    extraGroups = [
      "dialout" # for writing to serial
      "wheel"
      "networkmanager"
      "docker"
      "devices"
    ];
    shell = pkgs.zsh;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  clan.core.networking.targetHost = "root@127.0.0.1";

  networking.domain = "dark";

  # Set keyboard layout
  console.keyMap = "de";
  services.localtimed.enable = true;
  services.geoclue2 = {
    enable = true;
  };
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
    helix
    git
    fd
    ripgrep
  ];

  users.users.root = {
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB0d0JA20Vqn7I4lCte6Ne2EOmLZyMJyS9yIKJYXNLjbLwkQ4AYoQKantPBkTxR75M09E7d3j5heuWnCjWH45TrfQfe1EOSSC3ppCI6C6aIVlaNs+KhAYZS0m2Y8WkKn+TT5JLEa8yybYVN/RlZPOilpj/1QgjU6CQK+eJ1k/kK+QFXcwN82GDVh5kbTVcKUNp2tiyxFA+z9LY0xFDg/JHif2ROpjJVLQBJ+YPuOXZN5LDnVcuyLWKThjxy5srQ8iDjoxBg7dwLHjby5Mv41K4W61Gq6xM53gDEgfXk4cQhJnmx7jA/pUnsn2ZQDeww3hcc7vRf8soogXXz2KC9maiq0M/svaATsa9Ul4hrKnqPZP9Q8ScSEAUX+VI+x54iWrnW0p/yqBiRAzwsczdPzaQroUFTBxrq8R/n5TFdSHRMX7fYNOeVMjhfNca/gtfw9dYBVquCvuqUuFiRc0I7yK44rrMjjVQRcAbw6F8O7+04qWCmaJ8MPlmApwu2c05VMv9hiJo5p6PnzterRSLCqF6rIdhSnuOwrUIt1s/V+EEZXHCwSaNLaQJnYL0H9YjaIuGz4c8kVzxw4c0B6nl+hqW5y5/B2cuHiumnlRIDKOIzlv8ufhh21iN7QpIsPizahPezGoT1XqvzeXfH4qryo8O4yTN/PWoA+f7o9POU7L6hQ== lhebendanz@nixos"
    ];
  };

  # Perless nix activation
  services.userborn.enable = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes auto-allocate-uids cgroups
    '';
    settings = {
      auto-optimise-store = true;
      auto-allocate-uids = true;

      system-features = [
        "nixos-test"
        "uid-range"
      ];
    };
    gc.automatic = true;
    gc.dates = "daily";
    gc.options = "--delete-older-than 30d";
    settings.trusted-users = [
      "@wheel"
      config.clan.user-password.user
    ];
  };

  system.stateVersion = "24.11";
}
