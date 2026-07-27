{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.omnigent = pkgs.callPackage ./package.nix {
        uv2nix = inputs.uv2nix;
        pyproject-nix = inputs.pyproject-nix;
        pyproject-build-systems = inputs.pyproject-build-systems;
      };
    };
}
