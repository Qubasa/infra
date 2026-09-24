{
  description = "Qubasa's cLANs";

  inputs = {
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
    };

    slopo.url = "github:Qubasa/slopo";

    focus-timer = {
      url = "github:Qubasa/FocusTimer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    my-private-pkgs = {
      type = "git";
      url = "ssh://gitea@gitea.gchq.icu/Luis/my-private-nix-packages.git";
    };

    clan-community = {
      url = "git+https://git.clan.lol/clan/clan-community?ref=nim65s-harmonia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    unstable-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    qubasa-nixpkgs.url = "github:Qubasa/nixpkgs?ref=update_sunshine";
    nix-image-installer.url = "github:nix-community/nixos-images";

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.follows = "unstable-nixpkgs";

    qubasa-ai-tools = {
      url = "github:Qubasa/llm-agents.nix?ref=init_uncomment";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mics-skills = {
      url = "github:Mic92/mics-skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tincr = {
      url = "github:Mic92/tincr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    afk = {
      url = "github:Qubasa/afk";
    };

    # Own nixpkgs (not followed) so the cached muvm/libkrun/mesa builds resolve.
    munix.url = "git+https://git.clan.lol/clan/munix";

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
    };
    nix-index-database = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nix-index-database";
    };
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
    simple-nixos-mailserver = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    };
    chrome-pwa = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Qubasa/nixos-chrome-pwa";
    };

    systems.url = "github:nix-systems/default";
    flake-parts.follows = "clan-core/flake-parts";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          ./pkgs/mvm/flake-module.nix
          ./pkgs/omnigent/flake-module.nix
          ./pkgs/sunshine-display/flake-module.nix
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
              env.CLAN_NO_COMMIT = "1";
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
