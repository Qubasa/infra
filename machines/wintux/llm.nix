{
  flakeInputs,
  ...
}:

let
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";

in
{

  environment.systemPackages = [
    # my-claude-code
    ai-tools.claude-code
    ai-tools.opencode
    ai-tools.git-surgeon
    ai-tools.tuicr
    ai-tools.openspec
    ai-tools.nono
    # qubasa-ai-tools.opencode-quota
  ];

  # environment.etc."claude-code/managed-settings.json".text = builtins.toJSON managedSettings;

}
