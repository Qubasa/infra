{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mitmproxy
  ];

  programs.proxychains = {
    enable = true;
    proxies = {
      mitmproxy = {
        type = "http";
        port = 54321;
        host = "127.0.0.1";
        enable = true;
      };
    };
  };
}
