{
  flakeInputs,
  config,
  ...
}:
let
  # The tablet that streams this desktop is 3392x2400 (106:75), eDP-1 only has
  # 16:10 modes, so Moonlight letterboxes the stream. Neither DRM nor mutter can
  # add a mode at runtime: the mode is injected on the kernel command line below
  # and only activated while a Sunshine session runs.
  client = {
    width = 3392;
    height = 2400;
  };

  sunshine-display = flakeInputs.self.packages.x86_64-linux.sunshine-display;
  displayCmd = "${sunshine-display}/bin/sunshine-display";
in
{
  assertions = [
    {
      assertion = config.services.desktopManager.gnome.enable;
      message = ''
        machines/wintux/sunshine.nix: sunshine-display drives mutter's
        org.gnome.Mutter.DisplayConfig. GNOME is no longer enabled, so delete
        pkgs/sunshine-display and this hook, or port it to the new compositor.
      '';
    }
  ];

  # amdgpu keeps the panel on its native timing and downscales any non-native
  # eDP mode (dm_encoder_helper_atomic_check enables RMX_ASPECT), so the mode
  # only has to be advertised. MR = CVT with reduced blanking, which keeps the
  # pixel clock below the panel's own 2560x1600@165 timing.
  boot.kernelParams = [ "video=eDP-1:${toString client.width}x${toString client.height}MR@60" ];

  environment.systemPackages = [ sunshine-display ];

  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    autoStart = false;
    package = flakeInputs.qubasa-nixpkgs.legacyPackages.x86_64-linux.sunshine;

    settings = {
      lan_encryption_mode = 0;
      origin_web_ui_allowed = "pc";
      stream_audio = "disabled";
      # --aspect keeps the desktop at the tablet's ratio even when Moonlight
      # asks for a 16:9 stream, so the panel never renders stretched geometry.
      global_prep_cmd = builtins.toJSON [
        {
          do = "${displayCmd} apply --width ${toString client.width} --height ${toString client.height} --aspect ${toString client.width}:${toString client.height}";
          undo = "${displayCmd} revert";
          elevated = "false";
        }
      ];
    };

    applications = {
      env.PATH = "$(PATH):$(HOME)/.local/bin";
      apps = [
        { name = "Desktop"; }
        {
          name = "Steam Big Picture";
          detached = [ "setsid steam steam://open/bigpicture" ];
          prep-cmd = [
            {
              do = "";
              undo = "setsid steam steam://close/bigpicture";
            }
          ];
          image-path = "steam.png";
        }
      ];
    };
  };
}
