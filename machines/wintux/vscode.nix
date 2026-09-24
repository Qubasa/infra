{
  unstablePkgs,
  pkgs,
  lib,
  ...
}:

let
  # open-vsx ships jj-view's prebuilt @parcel/watcher without an rpath, so activation
  # dies on a missing libstdc++.so.6 and the JJ Log view never appears.
  jj-view = pkgs.open-vsx.jj-view.jj-view.overrideAttrs (
    old:
    lib.throwIf (lib.elem pkgs.autoPatchelfHook (old.nativeBuildInputs or [ ]))
      "machines/wintux/vscode.nix: nix-vscode-extensions now patchelfs jj-view, delete the jj-view override"
      {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.autoPatchelfHook ];
        buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.stdenv.cc.cc.lib ];
        autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];
      }
  );

  codium = unstablePkgs.vscode-with-extensions.override {
    vscode = pkgs.vscodium;
    vscodeExtensions = with pkgs.open-vsx; [
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
      jj-view
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
