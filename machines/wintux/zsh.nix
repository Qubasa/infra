{ pkgs, ... }:

{

  fonts.packages = [
    pkgs.nerdfonts
  ];

  programs.zsh = {
    enable = true;

    # With Oh-My-Zsh:
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "thefuck"
      ];
      theme = "gnzh";
    };

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
