{ config, pkgs, ... }:

{

  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;

  programs.direnv.enable = true;
  programs.nix-ld.enable = true;
  programs.chromium.enable = true;

  nixpkgs.config.allowUnfree = true;
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [
    chromium
    docker
    docker-compose
    virt-manager
    helix
    firefox
    vscode-fhs
    thunderbird
    kitty
    fd
    ripgrep-all
    man-pages
    posix_man_pages
    wget
    curl
    file
    fzf
    nmap
    calc
    tree
    gnupg
    patchelf
    p7zip
    radare2
    binutils
    jq
    remmina
    ldns
    traceroute
    tcpdump
    wireshark
  ];
}
