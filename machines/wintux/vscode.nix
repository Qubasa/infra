{ unstablePkgs, pkgs, ... }:

let
  vscode = unstablePkgs.vscode-with-extensions;
in
{
  environment.systemPackages = [
    (vscode.override {
      vscode = pkgs.vscodium;
      vscodeExtensions =
        with pkgs.open-vsx;
        [
          ms-python.python
          llvm-vs-code-extensions.vscode-clangd
          yzhang.markdown-all-in-one
          jnoortheen.nix-ide
          alefragnani.bookmarks
          tamasfe.even-better-toml
          james-yu.latex-workshop
          hashicorp.terraform
          matangover.mypy
          rust-lang.rust-analyzer
        ];
    })
  ];
}
