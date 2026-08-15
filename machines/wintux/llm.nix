{
  flakeInputs,
  pkgs,
  ...
}:

let
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";
  qubasa-ai-tools = flakeInputs.qubasa-ai-tools.packages."x86_64-linux";
  ghidra-cli = pkgs.callPackage ../../pkgs/ghidra-cli { };
  omnigent = flakeInputs.self.packages."x86_64-linux".omnigent;

in
{

  environment.systemPackages = [
    omnigent
    flakeInputs.slopo.packages.x86_64-linux.default
    ghidra-cli
    ai-tools.herdr
    qubasa-ai-tools.uncomment
    ai-tools.claude-code
    ai-tools.git-surgeon
    ai-tools.omp
    ai-tools.tuicr
    ai-tools.openspec
    ai-tools.jscpd
    ai-tools.agent-browser
    pkgs.openjdk25_headless
    pkgs.pueue
    # ai-tools.nono
  ];

  # environment.etc."claude-code/managed-settings.json".text = builtins.toJSON managedSettings;

}
