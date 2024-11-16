{ pkgs, lib, ... }:

let

  patch_atuin = pkgs.callPackage ../../pkgs/atuin { };
in
{
  fonts.packages = with pkgs; [
    nerdfonts
  ];

  environment.systemPackages = with pkgs; [
    zoxide
    patch_atuin
    lsd
  ];

  # # Shell history database
  services.atuin = {
    enable = true;
    package = patch_atuin;
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "lsd";
      cd = "z";
      lg = "lazygit";
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

    interactiveShellInit = ''
      eval "$(${lib.getExe pkgs.zoxide} init zsh)"
      eval "$(${lib.getExe patch_atuin} init zsh)"
    '';

    syntaxHighlighting.enable = true;

    histSize = 10000;
    autosuggestions = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
  };
}
