{
  description = "Qubasa's cLAN";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable?shallow=1";

    clan-core = {
      # url = "https://git.clan.lol/Qubasa/clan-core/archive/main.zip";
      # url = "path:/home/lhebendanz/Projects/clan-core";
      url = "git+https://git.clan.lol/clan/clan-core?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      # inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      # inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    data-mesher = {
      # inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "git+https://git.clan.lol/clan/data-mesher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      # inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      # inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chrome-pwa = {
      # inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:Qubasa/nixos-chrome-pwa";
      inputs.nixpkgs.follows = "nixpkgs";
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
            "disk-id"."instance1" = {
              roles.default.machines = [ "wintux" ];
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
