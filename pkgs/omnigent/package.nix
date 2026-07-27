{
  lib,
  stdenvNoCC,
  callPackage,
  fetchFromGitHub,
  makeWrapper,
  python312,
  # Runtime tools omnigent shells out to (harness install, git ops, terminals).
  # Added with --suffix so the user's own claude/codex/etc. still take priority.
  nodejs,
  git,
  tmux,
  uv,
  ripgrep,
  # uv2nix build infrastructure, threaded in from flake inputs by the overlay.
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:

let
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "omnigent-ai";
    repo = "omnigent";
    rev = "v${version}";
    hash = "sha256-Caypds51+SbeaQYLnbWtfNXbG12eL1KpZQEL/Vdw+l8=";
  };

  # The browser web UI (ap-web SPA), built offline from the same pinned src.
  # Injected into omnigent's package data below so the server can mount it.
  webUI = callPackage ./web-ui.nix { inherit src version; };

  # Load the uv workspace (pyproject.toml + uv.lock, including the sibling
  # sdks/* path members) and turn the lockfile into a nixpkgs python overlay.
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # Per-package build fixups.
  pyprojectOverrides = _final: prev: {
    # omnigent's setuptools build shells out to `npm` to bundle the browser web
    # UI, which needs network access unavailable in the nix sandbox. We instead
    # build the SPA separately (see web-ui.nix) and drop the prebuilt bundle
    # into the source tree here, so setuptools' `static/web-ui/**/*` package
    # data ships it into the wheel. OMNIGENT_SKIP_WEB_UI stays set so the
    # setup.py build hook never attempts its own (network-bound) npm build.
    omnigent = prev.omnigent.overrideAttrs (old: {
      # Home Manager exposes agent bundles from the read-only Nix store; make
      # omnigent's temp override copy writable before it rewrites config.yaml.
      patches = (old.patches or [ ]) ++ [
        ./writable-materialized-config.patch
      ];

      env = (old.env or { }) // {
        OMNIGENT_SKIP_WEB_UI = "true";
      };

      postPatch = (old.postPatch or "") + ''
        mkdir -p omnigent/server/static
        cp -r ${webUI} omnigent/server/static/web-ui
        chmod -R u+w omnigent/server/static/web-ui
      '';
    });
  };

  python = python312;

  pythonSet = (callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      overlay
      pyprojectOverrides
    ]
  );

  venv = pythonSet.mkVirtualEnv "omnigent-${version}-env" workspace.deps.default;

  runtimePath = lib.makeBinPath [
    nodejs
    git
    tmux
    uv
    ripgrep
  ];
in
stdenvNoCC.mkDerivation {
  pname = "omnigent";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    for bin in omnigent omni; do
      makeWrapper ${venv}/bin/$bin $out/bin/$bin \
        --suffix PATH : "${runtimePath}"
    done
    runHook postInstall
  '';

  passthru = {
    inherit venv pythonSet workspace;
  };

  meta = {
    description = "Open-source AI agent framework and meta-harness over Claude Code, Codex, and more";
    homepage = "https://omnigent.ai";
    license = lib.licenses.asl20;
    mainProgram = "omnigent";
    platforms = lib.platforms.unix;
  };
}
