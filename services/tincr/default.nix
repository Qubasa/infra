{ tincrModule }:
{ clanLib, lib, ... }:
let
  inherit (lib)
    all
    allUnique
    attrNames
    attrValues
    concatMapStringsSep
    concatStringsSep
    elem
    filterAttrs
    foldl'
    getExe
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkOption
    nameValuePair
    optional
    range
    replaceStrings
    substring
    types
    ;

  # tinc node names only allow [a-zA-Z0-9_].
  nodeName = replaceStrings [ "-" ] [ "_" ];

  hextets =
    hash: offset: count:
    concatMapStringsSep ":" (i: substring (offset + 4 * i) 4 hash) (range 0 (count - 1));

  # ULA /64 per instance, 64-bit host part per machine, both stable hashes.
  prefix =
    instanceName:
    let
      hash = builtins.hashString "sha256" "tincr-${instanceName}";
    in
    "fd${substring 0 2 hash}:${hextets hash 2 3}";

  meshIp =
    instanceName: machineName:
    "${prefix instanceName}:${hextets (builtins.hashString "sha256" machineName) 0 4}";

  # Both ends of a link must agree. Host files carry them so invitees inherit them.
  cryptoLines = [
    "SPTPSCipher = aes-256-gcm"
    "SPTPSKex = x25519-mlkem768"
  ];

  invitationSeparator = "#---------------------------------------------------------------#";

  # meshIp for the invited node name, at runtime.
  nodeIpScript = instanceName: ''
    hash=$(printf '%s' "$NODE" | sha256sum)
    ip="${prefix instanceName}:''${hash:0:4}:''${hash:4:4}:''${hash:8:4}:''${hash:12:4}"
  '';

  mkInvitationHooks =
    {
      pkgs,
      instanceName,
      package,
    }:
    {
      # The invitee gets its address and every peer's host file, not only the inviter's.
      created = pkgs.writeShellApplication {
        name = "tincr-${instanceName}-invitation-created";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnused
        ];
        text = ''
          ${nodeIpScript instanceName}
          tmp=$(mktemp "$INVITATION_FILE.XXXXXX")
          {
            sed '/^${invitationSeparator}$/,$d' "$INVITATION_FILE"
            printf 'Subnet = %s/128\nIfconfig = %s/64\nRoute = %s::/64\n' \
              "$ip" "$ip" "${prefix instanceName}"
            sed -n '/^${invitationSeparator}$/,$p' "$INVITATION_FILE"
            for host in /etc/tinc/${instanceName}/hosts/*; do
              if [ "$(basename "$host")" != "$NAME" ]; then
                printf 'Name = %s\n' "$(basename "$host")"
                cat "$host"
              fi
            done
          } > "$tmp"
          mv "$tmp" "$INVITATION_FILE"
        '';
      };

      # StrictSubnets: the inviter routes to the invitee before it is declared in `devices`.
      accepted = pkgs.writeShellApplication {
        name = "tincr-${instanceName}-invitation-accepted";
        runtimeInputs = [
          pkgs.coreutils
          package
        ];
        text = ''
          ${nodeIpScript instanceName}
          printf 'Subnet = %s/128\n' "$ip" >> "$HOST_FILE"
          tinc -n ${instanceName} --pidfile /run/tincr/${instanceName}.pid reload
        '';
      };
    };
in
{
  _class = "clan.service";
  manifest.name = "tincr";
  manifest.description = "tincr mesh VPN between all peers";
  manifest.categories = [
    "System"
    "Network"
  ];

  roles.peer = {
    description = "Mesh node. Every peer dials all peers that have endpoints.";
    interface = {
      options.endpoints = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "vpn.example.com"
          "203.0.113.7 655"
        ];
        description = ''
          Public addresses other peers dial to reach this machine, written as
          `Address =` lines (`host [port]`). Leave empty behind NAT.
        '';
      };

      options.devices = mkOption {
        type = types.attrsOf (types.strMatching "[A-Za-z0-9+/]{43}");
        default = { };
        example = {
          phone = "Yg4ZBtM/P0KUpVSXAfx1LhUMc88C6XeAG8KiR473G/L";
        };
        description = ''
          Non-clan nodes joined by invitation, as tinc node name to Ed25519 public key
          (from `/var/lib/tincr/<instance>/hosts/<name>` on the inviter). Every peer gets
          their host file, so they are reachable mesh-wide.
        '';
      };
    };

    perInstance =
      {
        instanceName,
        roles,
        machine,
        ...
      }:
      {
        nixosModule =
          { config, pkgs, ... }:
          let
            generator = "tincr-${instanceName}";
            peers = roles.peer.machines;
            peerNodes = map nodeName (attrNames peers);
            devices = foldl' (acc: peer: acc // peer.settings.devices) { } (attrValues peers);
            hooks = mkInvitationHooks {
              inherit pkgs instanceName;
              inherit (config.services.tincr) package;
            };

            publicKey =
              name:
              clanLib.getPublicValue {
                flake = config.clan.core.settings.directory;
                machine = name;
                inherit generator;
                file = "ed25519_key.pub";
              };

            hostFile = lines: concatStringsSep "\n" (lines ++ cryptoLines) + "\n";

            peerHostFile =
              name: peer:
              hostFile (
                [ "Subnet = ${meshIp instanceName name}/128" ]
                ++ optional (nodeName name != name) "Alias = ${name}"
                ++ map (endpoint: "Address = ${endpoint}") peer.settings.endpoints
                ++ [ "Ed25519PublicKey = ${publicKey name}" ]
              );

            deviceHostFile =
              name: key:
              hostFile [
                "Subnet = ${meshIp instanceName name}/128"
                "Ed25519PublicKey = ${key}"
              ];

            dialable = filterAttrs (name: peer: name != machine.name && peer.settings.endpoints != [ ]) peers;
          in
          {
            assertions = [
              {
                assertion = allUnique peerNodes;
                message = "tincr ${instanceName}: machine names collide after '-' -> '_' (${concatStringsSep ", " (attrNames peers)}).";
              }
              {
                assertion = all (name: builtins.match "[A-Za-z0-9_]+" name != null && !elem name peerNodes) (
                  attrNames devices
                );
                message = "tincr ${instanceName}: device names must match [A-Za-z0-9_]+ and not reuse a machine's node name (${concatStringsSep ", " (attrNames devices)}).";
              }
            ];

            clan.core.vars.generators.${generator} = {
              files."ed25519_key.priv" = { };
              files."ed25519_key.pub".secret = false;
              runtimeInputs = [
                config.services.tincr.package
                pkgs.coreutils
                pkgs.gnugrep
              ];
              script = ''
                export TMPDIR=/tmp
                tmp=$(mktemp -d)
                sptps_keypair "$out/ed25519_key.priv" "$tmp/ed25519_key.pub"
                grep -v -e '-----' "$tmp/ed25519_key.pub" | tr -d '\n' > "$out/ed25519_key.pub"
              '';
            };

            services.tincr.networks.${instanceName} = {
              nodeName = nodeName machine.name;
              ed25519PrivateKeyFile = config.clan.core.vars.generators.${generator}.files."ed25519_key.priv".path;
              addresses = [ "${meshIp instanceName machine.name}/64" ];
              connectTo = map nodeName (attrNames dialable);
              openFirewall = true;
              extraConfig = concatStringsSep "\n" (cryptoLines ++ [ "StrictSubnets = yes" ]) + "\n";
              dns = {
                enable = true;
                suffix = instanceName;
                address6 = "${prefix instanceName}::53";
              };
              hosts =
                mapAttrs' (name: peer: nameValuePair (nodeName name) (peerHostFile name peer)) peers
                // mapAttrs deviceHostFile devices;
            };

            environment.etc."tinc/${instanceName}/invitation-created".source = getExe hooks.created;
            environment.etc."tinc/${instanceName}/invitation-accepted".source = getExe hooks.accepted;

            # Upstream restarts only on tinc.conf changes, and StrictSubnets reads hosts/ at start.
            systemd.services."tincr-${instanceName}".restartTriggers = [
              config.environment.etc."tinc/${instanceName}/hosts".source
            ];
          };
      };
  };

  perMachine = _: {
    nixosModule =
      { config, ... }:
      let
        ports = mapAttrsToList (_: net: net.listenPort) (
          filterAttrs (_: net: net.enable) config.services.tincr.networks
        );
      in
      {
        imports = [ tincrModule ];
        # `tinc invite`, `tinc dump` and friends for operators.
        environment.systemPackages = [ config.services.tincr.package ];
        assertions = [
          {
            assertion = allUnique ports;
            message = "services.tincr.networks: every network needs its own listenPort (default 655).";
          }
        ];
      };
  };
}
