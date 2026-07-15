{
  flakeInputs,
  ...
}:

{
  environment.systemPackages = [
    flakeInputs.self.packages.x86_64-linux.mvm
  ];
}
