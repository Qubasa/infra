{
  flakeInputs,
  ...
}:

let
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";

in
{

  environment.systemPackages = [
    ai-tools.claude-code
    ai-tools.git-surgeon
    ai-tools.tuicr
    ai-tools.openspec
    ai-tools.jscpd
    # ai-tools.nono
    flakeInputs.self.packages.x86_64-linux.omnigent
  ];

  # environment.etc."claude-code/managed-settings.json".text = builtins.toJSON managedSettings;

}
