{ flakeInputs, ... }:
{
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    autoStart = false;
    package = flakeInputs.qubasa-nixpkgs.legacyPackages.x86_64-linux.sunshine;
  };
}
