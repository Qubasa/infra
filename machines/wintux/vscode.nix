{ unstablePkgs, pkgs, ... }:

let
  codium = unstablePkgs.vscode-with-extensions.override {
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
        jjk.jjk
      ];
  };
in
{
  environment.systemPackages = [
    codium
    # `code` is what git, jj and every tutorial call; keep it pointing at
    # the same VSCodium build that carries the extensions.
    (pkgs.runCommand "code-codium-alias" { } ''
      mkdir -p $out/bin
      ln -s ${codium}/bin/codium $out/bin/code
    '')
  ];
}
