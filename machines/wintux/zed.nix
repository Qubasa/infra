{
  pkgs,
  flakeInputs,
  ...
}:

let
  claudeCode = flakeInputs.nix-ai-tools.packages.x86_64-linux.claude-code;
in
{
  environment.systemPackages =
    (with pkgs; [
      zed-editor

      nixd
      nixfmt-rfc-style

      basedpyright
      ruff
      uv
      mypy
      (python3.withPackages (ps: [
        ps.python-lsp-server
        ps.pylsp-mypy
      ]))

      rust-analyzer
      lldb
      taplo

      bash-language-server
      shellcheck

      texlab
    ])
    ++ [
      claudeCode
    ];

  environment.etc."skel/.config/zed/settings.json".text = builtins.toJSON {
    telemetry = {
      diagnostics = false;
      metrics = false;
    };
    auto_update = false;
    format_on_save = "on";
    ensure_final_newline_on_save = true;
    remove_trailing_whitespace_on_save = true;
    tab_size = 4;
    soft_wrap = "editor_width";
    inlay_hints.enabled = true;
    git.inline_blame.enabled = true;
    terminal.shell.program = "zsh";

    auto_install_extensions = {
      latex = true;
    };

    languages = {
      Nix = {
        language_servers = [ "nixd" ];
        formatter = {
          external = {
            command = "nixfmt";
            arguments = [ "--quiet" ];
          };
        };
      };
      Python = {
        language_servers = [
          "basedpyright"
          "ruff"
          "pylsp"
        ];
        format_on_save = "on";
        formatter = [
          { code_actions.source.organizeImports.ruff = true; }
          { language_server.name = "ruff"; }
        ];
      };
      Rust = {
        language_servers = [ "rust-analyzer" ];
        tab_size = 4;
      };
      TOML = {
        language_servers = [ "taplo" ];
      };
      Bash = {
        language_servers = [ "bash-language-server" ];
        format_on_save = "off";
      };
      LaTeX = {
        language_servers = [ "texlab" ];
        format_on_save = "on";
        formatter = {
          external = {
            command = "tex-fmt";
            arguments = [ "--stdin" ];
          };
        };
        soft_wrap = "editor_width";
      };
    };

    lsp = {
      nixd.binary.path = "nixd";
      basedpyright.binary.path = "basedpyright-langserver";
      ruff.binary.path = "ruff";
      rust-analyzer.binary.path = "rust-analyzer";
      taplo.binary.path = "taplo";
      bash-language-server.binary.path = "bash-language-server";
      texlab = {
        binary.path = "texlab";
        settings.texlab = {
          build = {
            executable = "latexmk";
            args = [
              "-pdf"
              "-interaction=nonstopmode"
              "-synctex=1"
              "%f"
            ];
            onSave = false;
            forwardSearchAfter = false;
          };
          chktex = {
            onOpenAndSave = true;
            onEdit = false;
          };
          diagnosticsDelay = 300;
          formatterLineLength = 100;
        };
      };
      pylsp = {
        binary.path = "pylsp";
        settings.plugins = {
          pylsp_mypy = {
            enabled = true;
            live_mode = true;
            strict = false;
          };
          pycodestyle.enabled = false;
          pyflakes.enabled = false;
          mccabe.enabled = false;
          autopep8.enabled = false;
          yapf.enabled = false;
        };
      };
    };

    # agent_servers = {
    #   claude-acp = {
    #     type = "registry";
    #     env = {
    #       CLAUDE_CODE_EXECUTABLE = lib.getExe claudeCode;
    #     };
    #     default_config_options = {
    #       mode = "bypassPermissions";
    #     };
    #     favorite_config_option_values = {
    #       mode = [ "bypassPermissions" ];
    #     };
    #   };
    # };
  };
}
