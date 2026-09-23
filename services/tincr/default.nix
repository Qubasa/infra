{ tincrModule }:
{ clanLib, lib, ... }:
let
  inherit (lib)
    attrNames
    concatMapStringsSep
    concatStringsSep
    filterAttrs
    mapAttrs'
    mapAttrsToList
    mkOption
    nameValuePair
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

            publicKey =
              name:
              clanLib.getPublicValue {
                flake = config.clan.core.settings.directory;
                machine = name;
                inherit generator;
                file = "ed25519_key.pub";
              };

            hostFile =
              name: peer:
              concatStringsSep "\n" (
                [ "Subnet = ${meshIp instanceName name}/128" ]
                ++ map (endpoint: "Address = ${endpoint}") peer.settings.endpoints
                ++ [ "Ed25519PublicKey = ${publicKey name}" ]
              )
              + "\n";

            dialable = filterAttrs (
              name: peer: name != machine.name && peer.settings.endpoints != [ ]
            ) peers;
          in
          {
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
              ed25519PrivateKeyFile =
                config.clan.core.vars.generators.${generator}.files."ed25519_key.priv".path;
              addresses = [ "${meshIp instanceName machine.name}/64" ];
              connectTo = map nodeName (attrNames dialable);
              openFirewall = true;
              hosts = mapAttrs' (name: peer: nameValuePair (nodeName name) (hostFile name peer)) peers;
            };

            networking.extraHosts = concatStringsSep "\n" (
              mapAttrsToList (name: _: "${meshIp instanceName name} ${name}.${instanceName}") peers
            );
          };
      };
  };

  perMachine = _: {
    nixosModule.imports = [ tincrModule ];
  };
}
