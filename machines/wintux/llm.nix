{
  pkgs,
  flakeInputs,
  ...
}:

let
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";

  my-claude-code = pkgs.callPackage ../../pkgs/claude-code {
    claude-code = ai-tools.claude-code;
  };

  seccompArch = if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  applySeccomp = "${ai-tools.sandbox-runtime}/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/${seccompArch}/apply-seccomp";

  managedSettings = {
    sandbox = {
      enabled = true;
      enabledPlatforms = [ "linux" ];
      requireOnStartup = true;
      seccomp = {
        applyPath = applySeccomp;
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
  ];

  environment.etc."claude-code/managed-settings.json".text = builtins.toJSON managedSettings;

}
