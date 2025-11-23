{
  pkgs,
  flakeInputs,
  unstablePkgs,
  ...
}:

let

  pexpect-mcp = pkgs.python3.pkgs.callPackage ../../pkgs/pexpect-mcp { };

  my-claude-code = pkgs.callPackage ../../pkgs/claude-code {
    inherit pexpect-mcp;
    claude-code = unstablePkgs.claude-code;
  };
in
{
  imports = [
    # ../../modules/claude-code-gpt5
  ];

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

  # sysdig debugging tool -> gets stderr from all processes
  programs.sysdig.enable = true;

  # trace the kernel calls of a program
  programs.bcc.enable = true;

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
  nixpkgs.overlays = [ flakeInputs.nix-vscode-extensions.overlays.default ];

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
        converseen # image processor
      ]
    ++
      # Development Tools
      [
        # flakeInputs.ghostty.packages.x86_64-linux.ghostty-releasefast
        unstablePkgs.ghostty
        devtoolbox
        rust-analyzer
        nix-init # init nix packages in a directory
        helix
        nixd
        radare2
        mergiraf
        difftastic
        ast-grep # code search and replace
        shellcheck-minimal
        pueue # daemon to manage long running shell tasks
        gh # github cli
        tea # gitea cli
        unstablePkgs.codex # gpt cli
        my-claude-code # anthropic cli
      ]
    ++
      # Virtualization and Remote Desktop
      [
        google-cloud-sdk
        virt-manager
        virtiofsd # share filesystems
        moonlight-qt
        remmina
      ]
    ++
      # Terminals and Shell Utilities
      [
        # ghostty
        wl-clipboard
        git-lfs
        tmate
        zellij # tmux alternative
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
        dnsutils
        nettools
        lsof # list open files
      ]
    ++
      # File and Archive Utilities
      [
        pika-backup
        fd
        ripgrep
        file
        p7zip
      ]
    ++
      # Security and Encryption
      [
        gnupg
        bitwarden
        bitwarden-cli
        rbw # Bitwarden cli alternative
        pinentry # rbw dependency
      ]
    ++
      # System Tools
      [
        tldr
        man-pages
        man-pages-posix
        patchelf
        binutils
      ];
}
