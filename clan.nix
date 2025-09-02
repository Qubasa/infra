{
  meta.name = "Qubasas_Clan";

  # Testing the inventory
  inventory.instances = {
    sshd = {
      roles.server.tags = {
        all = { };
      };
    };

    matrix-synapse = {
      roles.default.machines."gchq-local" = { };
      roles.default.settings = {
        server_tld = "gchq.icu";
        app_domain = "element.gchq.icu";
        acmeEmail = "acme@qube.email";

        users = {
          "Qubasa" = {
            admin = true;
          };
        };
      };
    };

    dyndns = {
      roles.default.machines."gchq-local" = { };
      roles.default.settings = {
        server = {
          enable = true;
          domain = "home.gchq.icu";
          acmeEmail = "acme@qube.email";
        };
        period = 15;
        settings = {
          "all-gchq.icu" = {
            provider = "porkbun";
            domain = "gchq.icu";
            secret_field_name = "secret_api_key";
            extraSettings = {
              host = "@,element,gitea,home,bitwarden,cloud";
              ip_version = "ipv4";
              ipv6_suffix = "";
              # This is a pubkey. It is not a secret.
              api_key = "pk1_b0a5183f51a42c3459cdce3e58a4482c6696f417d6408035d19189c2b40425f1";
            };
          };
        };
      };
    };

    zerotier = {
      roles.controller.machines."wintux" = { };
      roles.peer.tags.all = { };
    };

    trusted-nix-caches = {
      roles.default.tags = {
        all = { };
      };
    };

    internet = {
      module = {
        name = "internet";
        input = "clan-core";
      };
      roles.default.machines.demo.settings.host = "root@192.168.122.87";
      roles.default.machines.wintux.settings.host = "root@127.0.0.1";
      roles.default.machines.gchq-local.settings.host = "root@home.gchq.icu";
      roles.default.machines.qube-email.settings.host = "root@qube.email";
    };

    tor = {
      roles.server.machines = {
        demo = { };
        gchq-local = { };
      };
      roles.client.machines = {
         wintux = {};
      };
    };

    user-root = {
      module = {
        name = "users";
        input = "clan-core";
      };
      roles.default.settings = {
        user = "root";
      };
      roles.default.tags = {
        all = { };
      };
    };
    user-lhebendanz =
      let
        username = "lhebendanz";
      in
      {
        module = {
          name = "users";
          input = "clan-core";
        };
        roles.default.machines = {
          wintux = { };
        };
        roles.default.settings = {
          user = username;
          groups = [
            "dialout" # for writing to serial
            "wheel"
            "networkmanager"
            "docker"
            "devices"
          ];
        };
        roles.default.extraModules = [
          # # FIXME: This doesn't work
          # (
          #   { pkgs, settings, ... }:
          #   {
          #     users.users."${username}".shell = pkgs.zsh;
          #   }
          # )
          ./users/lhebendanz.nix
        ];
      };

  };
}
