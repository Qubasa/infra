{
  lib,
  pkgs,
  writeShellApplication,
  claude-code,
  pexpect-mcp,
  claude-code-gpt5,
  redirectToGpt5 ? false,
}:

writeShellApplication {
  name = "claude";
  runtimeInputs = [
    claude-code
    pexpect-mcp
    claude-code-gpt5
    pkgs.pueue
  ];
  text = ''
    set -euo pipefail

    # Set shell to bash for Claude Code
    export SHELL=bash

    # Start pueued daemon if not already running
    if ! pueue status &>/dev/null; then
      echo "Starting pueue daemon..."
      pueued -d
    fi

    # if no arguments are provided:
    if [ "$#" -eq 0 ]; then
       claude mcp add pexpect -- pexpect-mcp || true
       claude mcp add --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: $(rbw get context7-api-key)" || true
    fi

    ${lib.optionalString redirectToGpt5 "export ANTHROPIC_BASE_URL=http://localhost:4000"}


    # Run the actual claude command
    exec claude "$@"
  '';
}
