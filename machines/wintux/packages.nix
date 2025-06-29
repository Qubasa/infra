{
  unstablePkgs,
  config,
  pkgs,
  ...
}:

{

  # Printing
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  programs.nix-index = {
    enable = true;
    enableZshIntegration = false;
    enableBashIntegration = false;
  };
  programs.command-not-found.enable = false;
  programs.nix-index-database.comma.enable = true;
  programs.direnv.enable = true;
  programs.nix-ld.enable = true;
  services.envfs.enable = true;

  # programs.chromium.enable = true;
  programs.thunderbird = {
    enable = true;
    policies = {
      DisableTelemetry = true;
    };
  };

  programs.lazygit = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./lazygit.json);
  };

  programs.git = {
    enable = true;
    config = builtins.fromJSON (builtins.readFile ./git.json);
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  services.udev.packages = with pkgs; [
    logitech-udev-rules
  ];

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
    with pkgs;
    # Web tools
    [
      signal-desktop
      brave
    ]
    ++
      # Office tools
      [
        solaar # logitech device tool
        gimp
        inkscape-with-extensions
        docker-compose
        libreoffice
        pdfarranger
        hplipWithPlugin # printer software
        zotero # reference manager
        tex-fmt
        texlivePackages.latexcheat
        texlivePackages.undergradmath
        texliveFull
      ]
    ++
      # Development Tools
      [
        # flakeInputs.ghostty.packages.x86_64-linux.ghostty-releasefast
        ghostty
        rust-analyzer
        unstablePkgs.claude-code
        helix
        nixd
        radare2
        mergiraf
        difftastic
      ]
    ++
      # Virtualization and Remote Desktop
      [
        google-cloud-sdk
        virt-manager
        remmina
      ]
    ++
      # Terminals and Shell Utilities
      [
        # ghostty
        wl-clipboard
        git-lfs
        tmate
        tmux
        delta
        pwgen
        fzf
        calc
        tree
        jq
      ]
    ++
      # Networking Tools
      [
        nmap
        traceroute
        tcpdump
        wireshark
        wget
        curl
        ldns
      ]
    ++
      # File and Archive Utilities
      [
        pika-backup
        fd
        ripgrep
        ripgrep-all
        file
        p7zip
      ]
    ++
      # Security and Encryption
      [
        gnupg
        bitwarden
        bitwarden-cli
      ]
    ++
      # System Tools
      [
        cheat
        man-pages
        man-pages-posix
        patchelf
        binutils
      ];
}
