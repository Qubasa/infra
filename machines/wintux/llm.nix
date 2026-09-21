{
  flakeInputs,
  pkgs,
  ...
}:

let
  ai-tools = flakeInputs.nix-ai-tools.packages."x86_64-linux";
  qubasa-ai-tools = flakeInputs.qubasa-ai-tools.packages."x86_64-linux";
  mics-skills = flakeInputs.mics-skills.packages."x86_64-linux";
  ghidra-cli = pkgs.callPackage ../../pkgs/ghidra-cli { };

  skillPackages = [
    mics-skills.kagi-search
    mics-skills.gmaps-cli
    mics-skills.pexpect-cli
  ];
in
{

  environment.systemPackages = [
    flakeInputs.slopo.packages.x86_64-linux.default
    flakeInputs.afk.packages.x86_64-linux.afk
    ghidra-cli
    pkgs.openjdk25_headless
    qubasa-ai-tools.uncomment
    qubasa-ai-tools.lemmalog
    ai-tools.claude-code
    ai-tools.git-surgeon
    ai-tools.omp
    ai-tools.tuicr
    ai-tools.openspec
    ai-tools.jscpd
    ai-tools.agent-browser
  ]
  ++ skillPackages;

  # mics-skills ship their SKILL.md under share/skills/<pname>; omp's claude
  # provider and claude-code itself both read ~/.claude/skills.
  systemd.user.tmpfiles.rules = map (
    p: "L+ %h/.claude/skills/${p.pname} - - - - ${p}/share/skills/${p.pname}"
  ) skillPackages;
}
