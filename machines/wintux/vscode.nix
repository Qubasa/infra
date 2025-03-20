{ flakeInputs, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscodeExtensions =
        with vscode-extensions;
        [
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
        ]
        ++ [ # from nix-vscode-extensions input
           # github.vscode-pull-request-github
          github.copilot
          github.copilot-chat
          ms-vscode-remote.remote-ssh
          eamodio.gitlens
          rust-lang.rust-analyzer
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          # {
          #    name = "cline";
          #    publisher = "saoudrizwan.claude-dev";
          #    version = "3.4.9";
          #    # sha256 = "sha256-YdHbJ3jju98EuEJQkhqCPvOglM1oRAxDpDr+709B/98=";
          # }
          # {
          #    name = "treefmt-vscode";
          #    publisher = "ibecker";
          #    version = "2.1.1";
          #    sha256 = "sha256-YdHbJ3jju98EuEJQkhqCPvOglM1oRAxDpDr+709B/98=";
          #  }
        ];
    })
  ];
}
