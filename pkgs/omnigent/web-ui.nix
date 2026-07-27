{
  lib,
  buildNpmPackage,
  src,
  version,
}:

# Build the omnigent browser web UI (the ``ap-web`` Vite/React SPA) offline.
#
# Upstream's setuptools build shells out to ``npm install && npm run build``
# (see the project ``setup.py``), which needs network access the Nix sandbox
# forbids - hence the API-only build. Here we build the SPA from the same
# pinned ``src`` as a ``buildNpmPackage`` derivation (deps fetched by hash,
# ``npm ci`` run offline) and expose the compiled bundle. package.nix injects
# the result into omnigent's ``server/static/web-ui`` so the server mounts it.
buildNpmPackage {
  pname = "omnigent-web-ui";
  inherit version;

  # The SPA is the ``ap-web`` subtree of the omnigent checkout.
  src = "${src}/ap-web";

  npmDepsHash = "sha256-zgrihNaPy7vRs2PlCsHf3LWorPDU1784+tqv+eufpag=";

  # ``npm run build`` is ``tsc -b && vite build``. Skip the ``tsc -b``
  # type-check (irrelevant to the runtime bundle, and a version skew there
  # would needlessly fail the derivation) and run vite directly, redirecting
  # its output to a local ``dist`` - vite.config.ts hard-codes ``outDir`` to
  # ``../omnigent/server/static/web-ui``, which lives outside this package root.
  buildPhase = ''
    runHook preBuild
    ./node_modules/.bin/vite build --outDir dist --emptyOutDir
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/. $out/
    runHook postInstall
  '';

  meta = {
    description = "Omnigent browser web UI (ap-web SPA) prebuilt for the Nix sandbox";
    homepage = "https://omnigent.ai";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
