{
  lib,
  pkgs,
  config,
  flakeInputs,
  ...
}:
let
  nixpkgs = flakeInputs.unstable-nixpkgs;

  flakeNix = pkgs.writeText "flake.nix" ''
    {
      description = "nixpkgs with unfree packages allowed";

      inputs.nixpkgs.url = "path:${nixpkgs}";

      outputs =
        { self, nixpkgs }:
        nixpkgs
        // {
          legacyPackages = builtins.mapAttrs (
            system: _:
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          ) nixpkgs.legacyPackages;
        };
    }
  '';

  # Pre-locked, because a flake in the store cannot write its own lock file.
  flakeLock = pkgs.writeText "flake.lock" (
    builtins.toJSON {
      version = 7;
      root = "root";
      nodes = {
        root.inputs.nixpkgs = "nixpkgs";
        nixpkgs = {
          locked = {
            type = "path";
            path = "${nixpkgs}";
            inherit (nixpkgs) narHash;
          };
          original = {
            type = "path";
            path = "${nixpkgs}";
          };
        };
      };
    }
  );

  nixpkgsUnfree = pkgs.runCommand "nixpkgs-unfree-flake" { } ''
    mkdir -p $out
    cp ${flakeNix} $out/flake.nix
    cp ${flakeLock} $out/flake.lock
  '';
in
{
  nix.registry.nixpkgs.to = {
    type = "path";
    path = "${nixpkgsUnfree}";
  };

  # <nixpkgs> defaults to flake:nixpkgs, which would now resolve to the wrapper
  # instead of a nixpkgs tree.
  nix.nixPath = [
    "nixpkgs=${nixpkgs}"
  ]
  ++ lib.optional config.nix.channel.enable "/nix/var/nix/profiles/per-user/root/channels";
}
