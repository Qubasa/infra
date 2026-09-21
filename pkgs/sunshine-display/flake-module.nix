{
  perSystem =
    { pkgs, ... }:
    {
      packages.sunshine-display = pkgs.callPackage ./default.nix { };
    };
}
