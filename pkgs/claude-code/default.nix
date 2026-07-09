{
  writeShellApplication,
  claude-code,
  fzf,
  jq,
  git,
}:

writeShellApplication {
  name = "claude";
  runtimeInputs = [
    claude-code
    fzf
    jq
    git
  ];
  text = ''
    set -euo pipefail

    # Set shell to bash for Claude Code
    export SHELL=bash

    # Run the actual claude command
    exec claude "$@"
  '';
}
