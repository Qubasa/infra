{
  lib,
  buildGoModule,
  fetchFromGitHub,
  tmux,
}:

buildGoModule rec {
  pname = "tmuxai";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "alvinunreal";
    repo = "tmuxai";
    rev = "v${version}";
    hash = "sha256-vCE5lR7s4FQczwcgQwh9yJEE8ErNc4nThBDqx8rhKgI=";
  };

  vendorHash = "sha256-VmYzzxbnNh3sApwak3cEd4bkp8VEpDFAeKzDlcnQiEg=";

  buildInputs = [ tmux ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Tests require network access and external dependencies
  doCheck = false;

  postInstall = ''
    # Install shell completions if they exist
    if [ -d "$out/share" ]; then
      mkdir -p $out/share/bash-completion/completions
      mkdir -p $out/share/zsh/site-functions
      mkdir -p $out/share/fish/vendor_completions.d
      
      if [ -f $out/bin/tmuxai ]; then
        $out/bin/tmuxai completion bash > $out/share/bash-completion/completions/tmuxai 2>/dev/null || true
        $out/bin/tmuxai completion zsh > $out/share/zsh/site-functions/_tmuxai 2>/dev/null || true
        $out/bin/tmuxai completion fish > $out/share/fish/vendor_completions.d/tmuxai.fish 2>/dev/null || true
      fi
    fi
  '';

  meta = with lib; {
    description = "Intelligent terminal assistant that lives inside your tmux sessions";
    homepage = "https://github.com/alvinunreal/tmuxai";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "tmuxai";
  };
}
