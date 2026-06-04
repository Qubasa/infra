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

    profiles=$(nono profile list --json | jq -r '.[] | "\(.name)\t\(.description)"')

    # Pre-select the profile whose name matches the current git repo root name
    query=""
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
      reponame=$(basename "$root")
      if cut -f1 <<<"$profiles" | grep -qxF "$reponame"; then
        query="$reponame"
      fi
    fi

    selection=$(
      printf '%s\n' "$profiles" |
        fzf --delimiter='\t' --nth=1 --with-nth=1,2 \
          --prompt='nono profile> ' --height='40%' --query="$query"
    )

    profile=$(cut -f1 <<<"$selection")
    if [ -z "$profile" ]; then
      echo "No profile selected" >&2
      exit 1
    fi

    # Run the actual claude command
    exec nono run --profile "$profile" --allow-cwd -- claude --dangerously-skip-permissions "$@"
  '';
}
