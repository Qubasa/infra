{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      packages.mvm = pkgs.callPackage ./default.nix {
        munix = inputs.munix;
        claudeCode = inputs.nix-ai-tools.packages.${system}.claude-code;
        zshModule = ../../modules/zsh.nix;
      };
    };
}
