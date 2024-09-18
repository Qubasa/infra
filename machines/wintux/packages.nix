{ config, inputs, pkgs, ... }:

let

  my_chromium = pkgs.chromium.override {
    enableWideVine = true;
    commandLineArgs = [
      "--enable-zero-copy"
      "--ignore-gpu-blocklist"
    ];
  };
in {

  # Enable Wayland support in all chromium based apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;
  programs.nix-index-database.comma.enable = true;
  programs.direnv.enable = true;
  programs.nix-ld.enable = true;


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
    nativeMessagingHosts.packages = with pkgs; [
      jabref 
    ];
  };
  programs.thunderbird = {
    enable = true;
    policies = {
      DisableTelemetry = true;
    };
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
      ] ++
      # Office tools
      [
        texliveFull
        jabref # reference manager
      ]
      ++
      # Development Tools
      [
        helix
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
      ]
    ++
      # System Tools
      [
        cheat
        texlivePackages.latexcheat
        texlivePackages.undergradmath
        man-pages
        posix_man_pages
        patchelf
        binutils
      ];
}
