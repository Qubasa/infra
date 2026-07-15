{
  writeText,
  writers,
  # munix flake, used to build the guest microVM with its own nixpkgs.
  munix,
  # claude-code package, injected into the guest.
  claudeCode,
  # Path to the shared zsh module (oh-my-zsh + direnv + zoxide).
  zshModule,
}:

let
  # Headless guest system: reuse munix's own nixpkgs evaluation (so muvm/mesa
  # match), strip the testvm GUI closure, add claude-code and dev tooling.
  guest =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [ zshModule ];

      programs.firefox.enable = lib.mkForce false;
      programs.dconf.enable = lib.mkForce false;
      fonts.packages = lib.mkForce [ ];

      # nix is driven through the host's daemon (socket bind-mounted by the mvm
      # wrapper), since the guest's /nix/store is read-only. Disable the guest's
      # own daemon so it does not fight over the bound socket path.
      nix.enable = true;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      systemd.services.nix-daemon.enable = lib.mkForce false;
      systemd.sockets.nix-daemon.enable = lib.mkForce false;

      users.users.appvm.shell = lib.mkForce pkgs.zsh;

      virtualisation.munix.defaultCommand = "${pkgs.bashInteractive}/bin/bash -l";

      # mkForce drops the testvm GUI closure, but the base system (corePackages)
      # and systemd (which provides sw/sbin/init) must be re-added or the guest
      # cannot boot. Packages added by imported modules (zsh, zoxide, direnv) are
      # dropped by mkForce too, so re-list the CLIs we want on PATH.
      environment.systemPackages = lib.mkForce (
        config.environment.corePackages
        ++ [
          config.systemd.package
          config.nix.package
          claudeCode
        ]
        ++ (with pkgs; [
          zsh
          zoxide
          direnv
          nix-direnv
          ripgrep
          fd
          jq
          git
          openssh
          cacert
          curl
          nodejs_22
        ])
      );
    };

  guestVm = munix.nixosConfigurations.testvm-x86_64.extendModules {
    modules = [ guest ];
  };

  munixBin = guestVm.config.system.build.munix;

  # Launches Claude once, from the first interactive prompt (job control is fully
  # active there, so Ctrl-Z suspends Claude and drops back to this shell). Removes
  # itself from PROMPT_COMMAND while preserving direnv's hook (an array element).
  mvmLaunch = writeText "mvm-launch.bash" ''
    mvm_launch() {
      local i
      for i in "''${!PROMPT_COMMAND[@]}"; do
        [ "''${PROMPT_COMMAND[$i]}" = mvm_launch ] && unset "PROMPT_COMMAND[$i]"
      done
      mvm_run
    }
    PROMPT_COMMAND+=(mvm_launch)
  '';

  src =
    builtins.replaceStrings [ "@munix@" "@mvm_launch@" ] [ "${munixBin}/bin/munix" "${mvmLaunch}" ]
      (builtins.readFile ./mvm.py);
in
writers.writePython3Bin "mvm" { flakeIgnore = [ "E501" ]; } src
