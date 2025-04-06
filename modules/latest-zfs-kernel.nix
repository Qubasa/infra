{
  lib,
  pkgs,
  config,
  ...
}:
let
  isUnstable = config.boot.zfs.package == pkgs.zfsUnstable;

  # Filter kernel packages for ZFS compatibility
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    # Ensure it's a standard kernel package name (e.g., linux_6_1)
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    # Ensure the package itself evaluates correctly
    && (builtins.tryEval kernelPackages).success
    # Check ZFS module compatibility based on whether stable or unstable ZFS is used
    # Directly access meta.broken, assuming it exists if the package evaluates successfully
    && (
      (!isUnstable && !kernelPackages.zfs.meta.broken)
      || (isUnstable && !kernelPackages.zfs_unstable.meta.broken)
    )
  ) pkgs.linuxKernel.packages;

  # Get the list of compatible kernel package sets (the values from the filtered attrset)
  compatibleKernelPackageSets = builtins.attrValues zfsCompatibleKernelPackages;

  # Sort the compatible package sets by kernel version (oldest first)
  sortedKernelPackageSets = lib.sort (
    a: b: lib.versionOlder a.kernel.version b.kernel.version
  ) compatibleKernelPackageSets;

  # Count how many compatible kernels we found
  kernelCount = builtins.length sortedKernelPackageSets;

  # Select the appropriate kernel package set
  selectedKernelPackageSet =
    if kernelCount == 0 then
      # No compatible kernels found - this is an error
      throw "No ZFS-compatible kernel packages found in pkgs.linuxKernel.packages."
    else if kernelCount == 1 then
      # Only one compatible kernel - use it (it's the latest and only option)
      lib.warn "Only one ZFS-compatible kernel found, using the latest." # Add if needed
      lib.last sortedKernelPackageSets # or lib.elemAt sortedKernelPackageSets 0
    else
      # At least two compatible kernels - select the second-to-last one.
      lib.last (lib.lists.init sortedKernelPackageSets)
      # Alternative using index: lib.elemAt sortedKernelPackageSets (kernelCount - 2)
    ;

in
{
  # Use the selected kernel package set
  boot.kernelPackages = selectedKernelPackageSet;

  # Optional: Add an assertion to fail evaluation early if no kernels are found
  assertions = [
    {
      assertion = kernelCount > 0;
      message = "ZFS is enabled, but no compatible kernel packages were found in pkgs.linuxKernel.packages.";
    }
  ];
}
