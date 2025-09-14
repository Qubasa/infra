{
  lib,
  uv2nix,
  pkgs,
  fetchFromGitHub,
  pyproject-nix,
  pyproject-build-systems,
  python312,
}:

let
  src = fetchFromGitHub {
    owner = "teremterem";
    repo = "claude-code-gpt-5";
    rev = "HEAD"; # Replace with specific commit or tag
    sha256 = "sha256-FcfunV5I6ZnNv04CAJhIVYAALYOdHyZaIZnyZIK34ms=";
  };

  # Load workspace
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = src;
  };

  # Create package overlay from workspace
  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # Build system fixes overlay
  pyprojectOverrides = final: prev: {
    # Add poetry-core to packages that need it but don't declare it properly
    litellm-enterprise = prev.litellm-enterprise.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        final.poetry-core
      ];
    });
    litellm-proxy-extras = prev.litellm-proxy-extras.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        final.poetry-core
      ];
    });
  };

  # Construct package set
  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages {
      python = python312;
    }).overrideScope
      (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          overlay
          pyprojectOverrides
        ]
      );

  # Package a virtual environment
  claude-code-gpt-5-env = pythonSet.mkVirtualEnv "claude-code-gpt-5" workspace.deps.default;

in
pkgs.writeShellScriptBin "claude-code-gpt-5" ''
  export PATH="${claude-code-gpt-5-env}/bin:$PATH"
  exec ${claude-code-gpt-5-env}/bin/litellm --config ${src}/config.yaml "$@"
''
