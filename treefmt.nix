# treefmt.nix
{ ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  programs.deadnix.enable = true;
  programs.nixfmt.enable = true;
  programs.shellcheck.enable = true;
}
