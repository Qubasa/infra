{ pkgs, ... }:

{
  boot.crashDump.enable = true;
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linux_6_6.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
          sha256 = "sha256-d0aYQi7lTF8ecERW83xlwGtRtOmosIZvNFgNhv744iY=";
        };
        version = "6.10";
        modDirVersion = "6.10.0";
      };
    }
  );
}
