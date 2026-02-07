{ unstablePkgs, pkgs, ... }:

let
  vscode = unstablePkgs.vscode-with-extensions;
in
{
  environment.systemPackages = [
    (vscode.override {
      vscodeExtensions =
        with pkgs.vscode-marketplace;
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
          charliermarsh.ruff
          ms-vscode-remote.remote-ssh
          rust-lang.rust-analyzer
        ]
        ++ (with pkgs.vscode-marketplace-release; [
          anthropic.claude-code
        ]);
    })
  ];
}
