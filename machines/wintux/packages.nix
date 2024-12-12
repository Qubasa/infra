{ config, pkgs, ... }:

let
  my_chromium = pkgs.chromium.override {
    enableWideVine = true;
  };
in
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

  programs.chromium.enable = true;
  programs.firefox = {
    enable = true;
    languagePacks = [
      "de"
      "en-US"
    ];
    policies = {
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
    };
    package = pkgs.firefox-beta;
  };
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

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
    with pkgs;
    # Web tools
    [
      my_chromium
      signal-desktop
    ]
    ++
      # Office tools
      [
        gimp
        inkscape-with-extensions
        docker-compose
        libreoffice
        pdfarranger
        hplipWithPlugin # printer software
        zotero # reference manager
        texlivePackages.latexcheat
        texlivePackages.undergradmath
        texliveFull
      ]
    ++
      # Development Tools
      [
        rust-analyzer
        helix
        nixd
        vscode-fhs
        radare2
      ]
    ++
      # Virtualization and Remote Desktop
      [
        virt-manager
        remmina
      ]
    ++
      # Terminals and Shell Utilities
      [
        kitty
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
