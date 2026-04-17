{
  writeShellApplication,
  claude-code,
  sandbox-runtime,
  stdenv,
}:

let
  arch = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  applySeccomp = "${sandbox-runtime}/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/${arch}/apply-seccomp";

  wrapper = writeShellApplication {
    name = "claude";
    runtimeInputs = [
      claude-code
    ];
    text = ''
      set -euo pipefail

      # Set shell to bash for Claude Code
      export SHELL=bash

      # Run the actual claude command
      exec claude "$@"
    '';
  };
in
wrapper.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit applySeccomp;
  };
  meta = (old.meta or { }) // {
    description = "claude-code wrapper that exposes the sandbox-runtime apply-seccomp path via passthru";
  };
})
