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
  src = lib.cleanSource ./claude-code-gpt-5-main;

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
  claude_code_gpt_5_env = pythonSet.mkVirtualEnv "claude-code-gpt-5" workspace.deps.default;

  package = pkgs.writeShellScriptBin "claude-code-gpt-5" ''
    export PATH="${claude_code_gpt_5_env}/bin:$PATH"
    exec ${claude_code_gpt_5_env}/bin/litellm --config ${src}/config.yaml "$@"
  '';

  devShell = pkgs.mkShell {
    packages = [
      claude_code_gpt_5_env
      pkgs.uv
    ];
    env =
      {
        # Don’t let uv manage a venv here
        UV_NO_SYNC = "1";
        # Force uv to use nixpkgs Python interpreter
        UV_PYTHON = python312.interpreter;
        # Prevent uv from downloading Python
        UV_PYTHON_DOWNLOADS = "never";
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        # Manylinux libs for projects that dlopen at runtime
        LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
      };

    shellHook = ''
      unset PYTHONPATH
      echo "Dev shell ready. The claude-code-gpt-5 virtualenv is on PATH."
    '';
  };
in
{
  # Keep previous behavior: nix-build (or nix build with flakes disabled) builds the package
  default = package;

  # Enter with: nix-shell -A devShell
  devShell = devShell;

  # Optional: expose these by name as well
  claude-code-gpt-5 = package;
  claude-code-gpt-5-env = claude_code_gpt_5_env;
}