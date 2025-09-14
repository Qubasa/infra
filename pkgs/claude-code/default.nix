{
  pkgs,
  writeShellApplication,
  claude-code,
  pexpect-mcp,
  claude-code-gpt5,
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

    OPENAI_API_KEY="$(rbw get openai-api-key)"
    export OPENAI_API_KEY

    export ANTHROPIC_BASE_URL=http://localhost:4000

    ANTHROPIC_API_KEY="$(rbw get anthropic-api-key)"
    export ANTHROPIC_API_KEY

    # RECOMMENDED: You are better off relying on the remaps below, rather than
    # setting the desired model in Claude Caude CLI via `claude --model gpt-5-...`
    # (even though you could also do that).
    #
    # The reason being that there are some built-in Agents in Claude Code that do
    # not inherit the model that was chosen globaly for the CLI and instead are
    # hardwired to always use specific models by Anthropic.
    #
    # (If you do not want to use these remaps but also want to avoid getting
    # warnings, then, instead of commenting them out, simply set them to empty
    # strings.)
    export REMAP_CLAUDE_HAIKU_TO=""
    export REMAP_CLAUDE_SONNET_TO=gpt-5-reason-medium
    export REMAP_CLAUDE_OPUS_TO=gpt-5-reason-high

    # Start litellm in the background using pueue
    # adding chatgpt-5 support to claude
    if ! pueue status --json | jq -e '.tasks[] | select(.command == "claude-code-gpt-5")' &>/dev/null; then
      pueue add claude-code-gpt-5
    fi

    # Run the actual claude command
    exec claude "$@"
  '';
}
