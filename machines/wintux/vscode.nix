{ unstablePkgs, pkgs, ... }:
{
  environment.systemPackages = [
    (unstablePkgs.vscode-with-extensions.override {
      vscodeExtensions = with pkgs.vscode-marketplace; [
        ms-python.python
        ms-toolsai.jupyter
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        ms-toolsai.vscode-jupyter-slideshow
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
        eamodio.gitlens
        rust-lang.rust-analyzer
      ] ++ (with pkgs.vscode-marketplace-release; [
          github.copilot
          github.copilot-chat        
      ]);
    })
  ];
}
