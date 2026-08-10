{
  flakeInputs,
  ...
}:

let
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";
  qubasa-ai-tools = flakeInputs.qubasa-ai-tools.packages."x86_64-linux";

in
{

  environment.systemPackages = [
    ai-tools.herdr
    qubasa-ai-tools.uncomment
    ai-tools.claude-code
    ai-tools.git-surgeon
    ai-tools.tuicr
    ai-tools.openspec
    ai-tools.jscpd
    ai-tools.agent-browser
    # ai-tools.nono
  ];

  # environment.etc."claude-code/managed-settings.json".text = builtins.toJSON managedSettings;

}
