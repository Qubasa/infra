{ pkgs, lib, ... }:

let

  patch_atuin = pkgs.callPackage ../../pkgs/atuin { };
in
{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  environment.systemPackages = with pkgs; [
    zoxide
    patch_atuin
    colordiff
    bat
    lsd
  ];

  # # Shell history database
  services.atuin = {
    enable = true;
    package = patch_atuin;
  };

  programs.bat = {
    enable = true;
  };

  environment.etc."zshrc.local".text = ''
      # Delay Atuin init until after zsh-vi-mode init to prevent overwriting of keybinds
      eval "$(${lib.getExe patch_atuin} init zsh --disable-up-arrow)"
      eval "$(${lib.getExe pkgs.zoxide} init zsh)"
  '';

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "lsd";
      cd = "z";
      lg = "lazygit";
      cat = "bat -p";
      diff = "colordiff";
      c = "wl-copy";
      v = "wl-paste";
    };

    # With Oh-My-Zsh:
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "gnzh";
    };

    syntaxHighlighting.enable = true;

  
    enableCompletion = false; # slows down session start when enabled
    autosuggestions = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
  };
}
