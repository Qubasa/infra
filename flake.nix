{
  description = "Qubasa's cLAN";


  inputs = {
    clan-core.url = "https://git.clan.lol/Qubasa/clan-core/archive/main.zip";
    # clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
    data-mesher.url = "https://git.clan.lol/clan/data-mesher/archive/decay.zip";

    simple-nixos-mailserver = {
      inputs.nixpkgs.follows = "clan-core";
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    };
  };

  outputs =
    inputs@{ self, ... }:
    let
      system = "x86_64-linux";
      pkgs = inputs.clan-core.inputs.nixpkgs.legacyPackages.${system};

      clan = inputs.clan-core.lib.buildClan {
        directory = self;
        meta = {
         name = "Qubasas_Clan"; # Ensure this is internet wide unique.
        };

        specialArgs = {
          inherit inputs;
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
          # wintux = {
          #   imports = [
          #     ./modules/shared.nix
          #     ./machines/wintux/configuration.nix
          #   ];
          #   nixpkgs.hostPlatform = system;
          # };
        };
      };
    in
    {
      # all machines managed by cLAN
      inherit (clan) nixosConfigurations clanInternals;


      # add the cLAN cli tool to the dev shell
      devShells.${system}.default = pkgs.mkShell {
        # packages = [ clan-core.packages.${system}.clan-cli ];
        packages = [ pkgs.python3 pkgs.mkpasswd ];
        shellHook = ''
          export PATH=$PATH:~/Projects/clan-core/pkgs/clan-cli/bin
        '';
      };
    };
}
