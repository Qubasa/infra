{
  pkgs,
  flakeInputs,
  ...
}:

let

  pexpect-mcp = pkgs.python3.pkgs.callPackage ../../pkgs/pexpect-mcp { };
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";

  my-claude-code = pkgs.callPackage ../../pkgs/claude-code {
    #inherit pexpect-mcp;
    claude-code = ai-tools.claude-code;
    #claude-code-router = ai-tools.claude-code-router;
  };
in
{

  environment.systemPackages = [
    my-claude-code
    ai-tools.claude-code-router
  ];

}
