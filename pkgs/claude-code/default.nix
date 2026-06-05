{
  writeShellApplication,
  claude-code,
  fzf,
  jq,
  git,
}:

writeShellApplication {
  name = "cn";
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

    # List profiles, sorting "claude-code-local" to the top so it is the
    # default highlighted entry while the full list stays visible.
    profiles=$(
      nono profile list --json |
        jq -r '
          sort_by(.name != "claude-code-local")[] |
          "\(.name)\t\(.description)"
        '
    )

    # Grant read+write to the git root, falling back to the current dir
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
      rwpath="$root"
    else
      rwpath="$PWD"
    fi

    # Seed the fzf query with the git repo root name so fzf fuzzy-matches it
    # query=""
    # if [ -n "$root" ]; then
    #   query=$(basename "$root")
    # fi

    selection=$(
      printf '%s\n' "$profiles" |
        fzf --delimiter='\t' --nth=1 --with-nth=1,2 \
          --layout=reverse --prompt='nono profile> ' --height='40%'
    )

    profile=$(cut -f1 <<<"$selection")
    if [ -z "$profile" ]; then
      echo "No profile selected" >&2
      exit 1
    fi

    # Inject the nono-sandbox skill so Claude reacts to kernel-level sandbox
    # denials correctly (run `nono why`, draft a profile) instead of retrying.
    skill_args=()
    for f in "$HOME"/.claude/plugins/marketplaces/*/plugins/nono/skills/nono-sandbox/SKILL.md; do
      if [ -r "$f" ]; then
        skill_args=(--append-system-prompt-file "$f")
        break
      fi
    done
    if [ "''${#skill_args[@]}" -eq 0 ]; then
      echo "warning: nono-sandbox SKILL.md not found; sandbox guidance not injected" >&2
    fi


    # Run the actual claude command
    exec nono run --profile "$profile" --allow "$rwpath" -- \
      claude --dangerously-skip-permissions \
      "''${skill_args[@]}" \
      "$@"
  '';
}
