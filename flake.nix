{
  description = "Qubasa's cLANs";

  inputs = {

    unstable-nixpkgs.url = "github:NixOS/nixpkgs/master?shallow=1";
    clan-core = {
      #url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
      url = "https://git.clan.lol/Qubasa/clan-core/archive/migrate_away_buildClan.zip";
      # url = "path:/home/lhebendanz/Projects/clan-core";
    };

    # vpn-bench = {
    #   url = "git+https://git.clan.lol/Qubasa/vpn-benchmark";
    # };

    nix-vscode-extensions = {
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
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

      clan = inputs.clan-core.lib.buildClan {
      #clan = inputs.clan-core.lib.clan {
        inherit self;
        #directory = self;
        meta = {
          name = "Qubasas_Clan"; # Ensure this is internet wide unique.
        };

        specialArgs = {
          flakeInputs = inputs;
          inherit unstablePkgs;
        };

        # Testing the inventory
        inventory = {
          machines = {
            wintux = {
              name = "wintux";
            };
          };
          instances = {
            sshd = {
              roles.server.tags = {
                all = { };
              };
            };

            trusted-nix-caches = {
              roles.default.tags = {
                all = { };
              };
            };
            # internet = {
            #   module = {
            #     name = "internet";
            #     input = "clan-core";
            #   };
            #   roles.default.settings = {
            #     host = "root@192.168.122.86";
            #   };
            #   roles.default.machines = {
            #     demo = { };
            #   };
            # };


            user-root = {
              module = {
                name = "users";
                input = "clan-core";
              };
              roles.default.settings = {
                user = "root";
              };
              roles.default.tags = {
                all = { };
              };
            };
            user-lhebendanz =
              let
                username = "lhebendanz";
              in
              {
                module = {
                  name = "users";
                  input = "clan-core";
                };
                roles.default.machines = {
                  wintux = { };
                };
                roles.default.settings = {
                  user = username;
                  groups = [
                    "dialout" # for writing to serial
                    "wheel"
                    "networkmanager"
                    "docker"
                    "devices"
                  ];
                };
                roles.default.extraModules = [
                  # # FIXME: This doesn't work
                  # (
                  #   { pkgs, settings, ... }:
                  #   {
                  #     users.users."${username}".shell = pkgs.zsh;
                  #   }
                  # )
                  ./users/lhebendanz.nix
                ];
              };
          };
          services = {
            # "disk-id"."instance1" = {
            #   roles.default.machines = [ "wintux" ];
            # };

            zerotier.default = {
              roles.controller.machines = [
                "gchq-local"
              ];
              roles.peer.machines = [
                "wintux"
                "qube-email"
              ];
            };
          };
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

            nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
            nixpkgs.hostPlatform = system;
            nixpkgs.config.allowUnfree = true;
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

      #inherit clan;
      # all machines managed by cLAN
      inherit (clan) nixosConfigurations clanInternals; 
      # new
      #inherit (clan.config) nixosConfigurations clanInternals;
      #clan = clan.config;

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

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
            #inputs.clan-core.packages.x86_64-linux.clan-cli
          ];
          shellHook = ''
            export GIT_ROOT="$(git rev-parse --show-toplevel)"
            export PATH=$PATH:~/Projects/clan-core/pkgs/clan-cli/bin
          '';
        }
      );
    };
}
