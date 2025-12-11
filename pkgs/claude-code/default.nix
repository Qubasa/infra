{
  writeShellApplication,
  claude-code
}:

writeShellApplication {
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
}
