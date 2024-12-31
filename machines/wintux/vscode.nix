{inputs, config, lib, pkgs, ...}:
let
 extensions = inputs.nix-vscode-extensions.extensions.x86_64-linux.vscode-marketplace-release;
in
{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        yzhang.markdown-all-in-one
        jnoortheen.nix-ide
        alefragnani.bookmarks
        tamasfe.even-better-toml
        james-yu.latex-workshop
      ] ++ (with extensions;
      [
        github.vscode-pull-request-github
        github.copilot
        github.copilot-chat
        ms-vscode-remote.remote-ssh
        eamodio.gitlens
        rust-lang.rust-analyzer
      ])
      ++ (with pkgs.vscode-utils.extensionsFromVscodeMarketplace; [
      ]);
    })
  ];
}
