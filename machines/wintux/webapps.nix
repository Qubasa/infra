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
}
