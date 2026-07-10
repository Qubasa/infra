{
  flakeInputs,
  pkgs,
  ...
}:

let
  system = "x86_64-linux";
  claudeCode = flakeInputs.nix-ai-tools.packages.${system}.claude-code;

  # Headless guest system: reuse munix's own nixpkgs evaluation (so muvm/mesa
  # match), strip the testvm GUI closure, add claude-code and dev tooling.
  guest =
    { pkgs, lib, ... }:
    {
      programs.firefox.enable = lib.mkForce false;
      programs.dconf.enable = lib.mkForce false;
      fonts.packages = lib.mkForce [ ];

      virtualisation.munix.defaultCommand = "${pkgs.bashInteractive}/bin/bash -l";

      environment.systemPackages = lib.mkForce (
        (with pkgs; [
          bashInteractive
          coreutils-full
          gnused
          gnugrep
          gawk
          findutils
          gnutar
          gzip
          xz
          which
          less
          ripgrep
          fd
          jq
          git
          openssh
          cacert
          curl
          nodejs_22
        ])
        ++ [ claudeCode ]
      );
    };

  claudeGuest = flakeInputs.munix.nixosConfigurations.testvm-x86_64.extendModules {
    modules = [ guest ];
  };

  munixBin = claudeGuest.config.system.build.munix;

  claudevm = pkgs.writeShellApplication {
    name = "claudevm";
    text = ''
      workdir="$(pwd -P)"
      home="''${HOME:?HOME is not set}"
      guest_home="/home/appvm"

      args=(
        --no-gpu
        --no-wayland
        --no-pipewire
        --bind "$workdir" "$workdir"
      )

      # Claude login/config, read-write so token refreshes persist.
      if [[ -e "$home/.claude" ]]; then
        args+=(--bind "$home/.claude" "$guest_home/.claude")
      fi
      if [[ -e "$home/.claude.json" ]]; then
        args+=(--bind "$home/.claude.json" "$guest_home/.claude.json")
      fi

      # Dev config, read-only.
      if [[ -e "$home/.gitconfig" ]]; then
        args+=(--ro-bind "$home/.gitconfig" "$guest_home/.gitconfig")
      fi
      if [[ -e "$home/.config/git" ]]; then
        args+=(--ro-bind "$home/.config/git" "$guest_home/.config/git")
      fi
      if [[ -e "$home/.ssh/known_hosts" ]]; then
        args+=(--ro-bind "$home/.ssh/known_hosts" "$guest_home/.ssh/known_hosts")
      fi

      # Single quotes are deliberate: $0/$@ expand inside the guest's bash.
      # shellcheck disable=SC2016
      exec ${munixBin}/bin/munix "''${args[@]}" -- \
        bash -lc 'export HOME=/home/appvm; cd "$0" && exec claude --dangerously-skip-permissions "$@"' \
        "$workdir" "$@"
    '';
  };
in
{
  environment.systemPackages = [ claudevm ];
}
