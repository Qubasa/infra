{
  description = "Qubasa's cLANs";

  inputs = {

    unstable-nixpkgs.url = "github:NixOS/nixpkgs/master?shallow=1";
    clan-core = {
      url = "https://git.clan.lol/Qubasa/clan-core/archive/demo.zip";
      # url = "https://git.clan.lol/Qubasa/clan-core/archive/deploy_network.zip";
      # url = "https://git.clan.lol/Qubasa/clan-core/archive/networking_2.zip";
      #url = "path:///home/lhebendanz/Projects/clan-core";
      # url = "path:/home/lhebendanz/Projects/clan-core";
    };

    # vpn-bench = {
    #   url = "git+https://git.clan.lol/Qubasa/vpn-benchmark";
    # };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
    };
    nix-index-database = {
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:nix-community/nix-index-database";
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
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:Qubasa/nixos-chrome-pwa";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      systems,
      unstable-nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      # 123
      # Override the unstable-nixpkgs with allowUnfree set to true
      unstablePkgs = import unstable-nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
        };
      };
      # Small tool to iterate over each systems
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = eachSystem (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

      clan = inputs.clan-core.lib.clan {
        imports = [ ./clan.nix ];

        inherit self;

        specialArgs = {
          flakeInputs = inputs;
          inherit unstablePkgs;
        };

        machines = {
          gchq-local = {
            imports = [
              ./modules/shared.nix

            ];
            nixpkgs.hostPlatform = system;
          };
          qube-email = {
            imports = [
              ./modules/shared.nix
            ];

            nixpkgs.hostPlatform = system;
          };
          wintux = {
            imports = [
              ./modules/shared.nix
            ];
            nixpkgs.hostPlatform = system;
          };
        };

        templates.disko = {
          "single-disk" = {
            description = "A simple ext4 disk with a single partition";
            path = ./modules;
          };
        };
      };
    in
    {

      inherit (clan.config) nixosConfigurations clanInternals;
      clan = clan.config;

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      flake = {
        myDirtyRev = self.sourceInfo.dirtyRev;
      };

      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      devShell = eachSystem (
        pkgs:
        pkgs.mkShell {
          packages = [
            pkgs.python3
            pkgs.python3Packages.argcomplete
            pkgs.mkpasswd
            # inputs.clan-core.packages.x86_64-linux.clan-cli
          ];
          shellHook = ''
            export GIT_ROOT="$(git rev-parse --show-toplevel)"
            export PATH=$PATH:~/Projects/clan-core/pkgs/clan-cli/bin
          '';
        }
      );
    };
}
