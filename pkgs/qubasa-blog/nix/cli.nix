{
  writeShellApplication,
  util-linux,
  nodejs_24,
  pnpm_10,
}:
writeShellApplication {
  name = "qubasa-blog";
  runtimeInputs = [
    util-linux
    nodejs_24
    pnpm_10
  ];
  text = builtins.readFile ./cli.sh;
  passthru = {
    pnpm = pnpm_10;
  };
}
