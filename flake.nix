{
  description = "Qubasa's cLAN";

  inputs = {

    # clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
    clan-core.url = "https://git.clan.lol/Qubasa/clan-core/archive/main.zip";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
    };
    data-mesher = {
      url = "git+https://git.clan.lol/clan/data-mesher";
      # inputs.nixpkgs.follows = "clan-core";
    };
    treefmt-nix = {
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
    simple-nixos-mailserver = {
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    };
    chrome-pwa = {
      url = "github:Qubasa/nixos-chrome-pwa";
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      system = "x86_64-linux";

      # Small tool to iterate over each systems
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = eachSystem (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

      clan = inputs.clan-core.lib.buildClan {
        directory = self;
        meta = {
          name = "Qubasas_Clan"; # Ensure this is internet wide unique.
        };

        specialArgs = {
          inherit inputs;
        };

        # Testing the inventory
        inventory = {
          machines = {
            wintux = {
              name = "wintux";
            };
          };
          services = {
            "user-password"."instance1" = {
              meta.name = "instance1";
              roles.default.machines = [ "wintux" ];
              config = {
                user = "lhebendanz";
              };
            };
          };
        };

        machines = {
          gchq-local = {
            imports = [
              ./modules/shared.nix
              ./machines/gchq-local/configuration.nix
            ];

            nixpkgs.hostPlatform = system;
          };
          qube-email = {
            imports = [
              ./modules/shared.nix
              ./machines/qube-email/configuration.nix
            ];

            nixpkgs.hostPlatform = system;
          };
          demo = {
            imports = [
              ./modules/shared.nix
              ./machines/demo/configuration.nix
            ];
            nixpkgs.hostPlatform = system;
          };
          wintux = {
            imports = [
              ./modules/shared.nix
              ./machines/wintux/configuration.nix
            ];
            nixpkgs.hostPlatform = system;
          };
        };
      };
    in
    {
      # all machines managed by cLAN
      inherit (clan) nixosConfigurations clanInternals;

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      devShell = eachSystem (
        pkgs:
        pkgs.mkShell {
          packages = [
            pkgs.python3
            pkgs.mkpasswd
          ];
          shellHook = ''
            export PATH=$PATH:~/Projects/clan-core/pkgs/clan-cli/bin
          '';
        }
      );
    };
}
