{
  description = "Qubasa's cLANs";

  inputs = {
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
      # url = "https://git.clan.lol/Qubasa/clan-core/archive/main.zip?ref=add_target_machine_option";
      # url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
    };

    focus-timer = {
      url = "github:Qubasa/FocusTimer";
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
    };

    my-private-pkgs = {
      type = "git";
      url = "ssh://gitea@gitea.gchq.icu/Luis/my-private-nix-packages.git";
    };

    clan-community = {
      url = "git+https://git.clan.lol/clan/clan-community?ref=nim65s-harmonia";
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
    };

    unstable-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable?shallow=1";
    qubasa-nixpkgs.url = "github:Qubasa/nixpkgs?ref=update_sunshine";
    nix-image-installer.url = "github:nix-community/nixos-images";

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
    };

    nixpkgs.follows = "unstable-nixpkgs";

    qubasa-ai-tools = {
      url = "github:Qubasa/llm-agents.nix?ref=opencode-quota";
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
    };

    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
    };

    # Own nixpkgs (not followed) so the cached muvm/libkrun/mesa builds resolve.
    munix.url = "git+https://git.clan.lol/clan/munix";

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
      # url = "gitlab:simple-nixos-mailserver/nixos-mailserver/44c63067d4ca9548c14b54620eaa9b981bc9c9db";
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    };
    chrome-pwa = {
      inputs.nixpkgs.follows = "clan-core/nixpkgs";
      url = "github:Qubasa/nixos-chrome-pwa";
    };

    systems.url = "github:nix-systems/default";
    flake-parts.follows = "clan-core/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      let
        system = "x86_64-linux";
        # Override the unstable-nixpkgs with allowUnfree set to true
        unstablePkgs = import inputs.unstable-nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        systems = import inputs.systems;

        imports = [
          inputs.clan-core.flakeModules.default
          inputs.treefmt-nix.flakeModule
          ./pkgs/qubasa-blog/flake-module.nix
        ];

        clan = {
          imports = [ ./clan.nix ];

          specialArgs = {
            flakeInputs = inputs;
            inherit unstablePkgs;
          };

          machines = {
            gchq-local = {
              imports = [ ./modules/shared.nix ];
              nixpkgs.hostPlatform = system;
            };
            qube-email = {
              imports = [ ./modules/shared.nix ];
              nixpkgs.hostPlatform = system;
            };
            wintux = {
              imports = [ ./modules/shared.nix ];
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

        flake = {
          myDirtyRev = self.sourceInfo.dirtyRev;
        };

        perSystem =
          { pkgs, ... }:
          {
            treefmt = import ./treefmt.nix;

            devShells.default = pkgs.mkShell {
              packages = [
                pkgs.python3
                pkgs.python3Packages.argcomplete
                pkgs.mkpasswd
                # inputs.clan-core.packages.x86_64-linux.clan-cli
              ];
              shellHook = ''
                export GIT_ROOT="$(git rev-parse --show-toplevel)"
                export PATH=$PATH:~/Projects/clan-core/pkgs/clan-cli/bin
                # export PATH=$PATH:~/Projects/clan-core/buildHostPr/pkgs/clan-cli/bin
              '';
            };
          };
      }
    );
}
