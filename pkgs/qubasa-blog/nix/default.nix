{
  lib,
  stdenv,
  nodejs_24,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "qubasa-blog";
  version = "0.0.1";

  # playwright is a transitive dev dep of svelte-md but mermaid rendering is
  # disabled, so never fetch browsers during install.
  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  src =
    let
      root = toString ../.;
      excluded =
        rel:
        (rel == "build")
        || (lib.hasPrefix "build/" rel)
        || (
          lib.hasInfix "node_modules" rel
          || lib.hasPrefix ".svelte-kit" rel
          || lib.hasPrefix ".direnv" rel
          || lib.hasPrefix "src/lib/generated" rel
          || lib.hasPrefix "src/routes/(site)/blog" rel
        );
    in
    lib.cleanSourceWith {
      name = "qubasa-blog-src";
      src = ../.;
      filter = path: _type: !excluded (lib.removePrefix "${root}/" (toString path));
    };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-uqYuIqL+wlxM8IrJfvb2mXt6bSrzIcnxEN2J4oSZO5I=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm_10
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv build $out
    runHook postInstall
  '';
})
