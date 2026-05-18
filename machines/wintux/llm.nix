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

  # Sensitive paths Write/Edit/Read should never touch.
  # The bash sandbox blocks shell writes, but Read/Edit/Write tools bypass it
  # and need their own permission rules.
  sensitivePaths = [
    "~/.bashrc"
    "~/.zshrc"
    "~/.bash_profile"
    "~/.zshenv"
    "~/.profile"
    "~/.ssh/**"
    "~/.gnupg/**"
    "~/.aws/**"
    "~/.azure/**"
    "~/.config/gh/**"
    "~/.git-credentials"
    "~/.docker/config.json"
    "~/.kube/**"
    "~/.npmrc"
    "~/.npm/**"
    "~/.pypirc"
    "~/.gem/credentials"
    "~/.claude/settings.json"
    "~/.config/claude/**"
    "/etc/**"
    "/usr/**"
    "/var/**"
    "/boot/**"
    "/nix/store/**"
    "/nix/var/**"
  ];

  toolGuard = tool: paths: map (p: "${tool}(${p})") paths;

  managedSettings = {
    sandbox = {
      enabled = true;
      enabledPlatforms = [ "linux" ];
      requireOnStartup = true;
      seccomp = {
        applyPath = applySeccomp;
      };
    };
    permissions = {
      deny =
        (toolGuard "Write" sensitivePaths)
        ++ (toolGuard "Edit" sensitivePaths)
        ++ (toolGuard "Read" sensitivePaths);
    };
  };
in
{

  environment.systemPackages = [
    my-claude-code
    ai-tools.opencode
    ai-tools.coderabbit-cli
    ai-tools.tuicr
    ai-tools.openspec
    ai-tools.workmux
  ];

  environment.etc."claude-code/managed-settings.json".text = builtins.toJSON managedSettings;

}
