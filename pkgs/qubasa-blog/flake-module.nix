{
  perSystem =
    { pkgs, ... }:
    let
      blog-cli = pkgs.callPackage ./nix/cli.nix { };
    in
    {
      packages.qubasa-blog = pkgs.callPackage ./nix/default.nix { };
      packages.qubasa-blog-cli = blog-cli;

      devShells.qubasa-blog = pkgs.mkShell {
        packages = [
          pkgs.nodejs_24
          pkgs.pnpm_10
          pkgs.util-linux
          blog-cli
        ];

        shellHook = ''
          export QUBASA_BLOG_DIR="$(git rev-parse --show-toplevel)/pkgs/qubasa-blog"
        '';
      };
    };
}
