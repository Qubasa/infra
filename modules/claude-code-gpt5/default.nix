{
  pkgs,
  config,
  lib,
  flakeInputs,
  ...
}:

let
  claude-code-gpt5 = pkgs.callPackage ../../pkgs/claude-code-gpt5 {
    uv2nix = flakeInputs.uv2nix;
    pyproject-nix = flakeInputs.pyproject-nix;
    python312 = pkgs.python312;
    pyproject-build-systems = flakeInputs.pyproject-build-systems;
  };
  cfg = config.services.claude-code-gpt5;
in
{
  options.services.claude-code-gpt5.enable = lib.mkEnableOption "Claude Code GPT-5 litellm proxy user service";

  config = lib.mkIf cfg.enable {
    systemd.user.services.claude-code-gpt5 = {
      enable = true;
      description = "Claude Code GPT-5 litellm proxy";
      path = [ claude-code-gpt5 pkgs.rbw];
      script = ''
        set -euo pipefail

        export OPENAI_BASE_URL=https://openrouter.ai/api/v1
        export ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1

        OPENAI_API_KEY="$(rbw get openrouter-api-key)"
        export OPENAI_API_KEY

        ANTHROPIC_API_KEY="$(rbw get openrouter-api-key)"
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
        export REMAP_CLAUDE_HAIKU_TO=gpt-5-nano-reason-minimal
        export REMAP_CLAUDE_SONNET_TO=gpt-5-reason-medium
        export REMAP_CLAUDE_OPUS_TO=gpt-5-reason-high


        exec claude-code-gpt-5
      '';
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
