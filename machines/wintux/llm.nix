{
  pkgs,
  flakeInputs,
  ...
}:

let
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";

  my-claude-code = pkgs.callPackage ../../pkgs/claude-code {
    claude-code = ai-tools.claude-code;
    sandbox-runtime = ai-tools.sandbox-runtime;
  };

  managedSettings = {
    sandbox = {
      enabled = true;
      enabledPlatforms = [ "linux" ];
      requireOnStartup = true;
      seccomp = {
        applyPath = my-claude-code.applySeccomp;
      };
    };
  };
in
{

  environment.systemPackages = [
    my-claude-code
    ai-tools.coderabbit-cli
    ai-tools.tuicr
    ai-tools.openspec
    ai-tools.claudebox
  ];

  environment.etc."claude-code/managed-settings.json".text = builtins.toJSON managedSettings;

}
