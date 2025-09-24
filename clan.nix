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

    monitoring = {
      roles.telegraf.machines."gchq-local" = {};
    };

    admin = {
      roles.default.tags.all = { };
      roles.default.settings = {
        allowedKeys = {
          "qubasa" =
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB0d0JA20Vqn7I4lCte6Ne2EOmLZyMJyS9yIKJYXNLjbLwkQ4AYoQKantPBkTxR75M09E7d3j5heuWnCjWH45TrfQfe1EOSSC3ppCI6C6aIVlaNs+KhAYZS0m2Y8WkKn+TT5JLEa8yybYVN/RlZPOilpj/1QgjU6CQK+eJ1k/kK+QFXcwN82GDVh5kbTVcKUNp2tiyxFA+z9LY0xFDg/JHif2ROpjJVLQBJ+YPuOXZN5LDnVcuyLWKThjxy5srQ8iDjoxBg7dwLHjby5Mv41K4W61Gq6xM53gDEgfXk4cQhJnmx7jA/pUnsn2ZQDeww3hcc7vRf8soogXXz2KC9maiq0M/svaATsa9Ul4hrKnqPZP9Q8ScSEAUX+VI+x54iWrnW0p/yqBiRAzwsczdPzaQroUFTBxrq8R/n5TFdSHRMX7fYNOeVMjhfNca/gtfw9dYBVquCvuqUuFiRc0I7yK44rrMjjVQRcAbw6F8O7+04qWCmaJ8MPlmApwu2c05VMv9hiJo5p6PnzterRSLCqF6rIdhSnuOwrUIt1s/V+EEZXHCwSaNLaQJnYL0H9YjaIuGz4c8kVzxw4c0B6nl+hqW5y5/B2cuHiumnlRIDKOIzlv8ufhh21iN7QpIsPizahPezGoT1XqvzeXfH4qryo8O4yTN/PWoA+f7o9POU7L6hQ== lhebendanz@nixos
";
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
      roles.default.machines.demo.settings.host = "root@192.168.122.67";
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
        wintux = { };
      };
    };

    borgbackup = {
      roles.client.machines."gchq-local".settings = {
        destinations."storagebox" = {
          repo = "u494682@$u494682.your-storagebox.de:/./borgbackup";
          rsh = ''ssh -oPort=23 -i /run/secrets/vars/borgbackup/borgbackup.ssh'';
        };
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
