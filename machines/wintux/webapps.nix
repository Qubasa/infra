{ ... }:

{

  services.open-webui = {
    enable = true;
    port = 2712;
  };

  networking.hosts = {
    "127.0.0.1" = [
      "openwebui.local"
      "kimai.local"
    ];
  };

  services.nginx = {
    enable = true;
    defaultListen = [
      {
        addr = "localhost";
        ssl = false;
      }
    ];
    virtualHosts = {
      "openwebui.local" = {
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://localhost:2712";
        };
      };
      "kimai.local" = {
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://localhost:8001";
        };
      };
    };
  };
}
