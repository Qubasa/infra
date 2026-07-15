{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = lib.mkDefault true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "gnzh";
    };

    interactiveShellInit = ''
      eval "$(${lib.getExe pkgs.zoxide} init zsh)"
    '';
  };

  # direnv's zsh/bash hooks are installed natively via programs.zsh/bash init.
  programs.direnv.enable = lib.mkDefault true;

  environment.systemPackages = [ pkgs.zoxide ];
}
