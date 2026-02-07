  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    mirrorBoot = idx: {
      # suffix is to prevent disk name collisions
      name = idx;
      type = "disk";
      device = "/dev/disk/by-id/${idx}";
      content = {
        type = "gpt";
        partitions = {
          "boot" = {
            size = "1M";
            type = "EF02"; # for grub MBR
            priority = 1;
          };
          "ESP" = lib.mkIf (idx == "ata-HGST_HUS726020ALE610_K5HEJXVD") {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "nofail" ];
            };
          };
          "root" = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };
  in
  {
    imports = [ ];

    config = {

      clan.core.vars.generators.zfs = {
        files.key.neededFor = "partitioning";
        runtimeInputs = [
          pkgs.xkcdpass
          pkgs.xxd
        ];
        script = ''
          xkcdpass -d - -n 8 | tr -d '\n' > $out/key
        '';
      };

      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        devices = [
          "/dev/disk/by-id/ata-HGST_HUS726020ALE610_K5HEJXVD"
          "/dev/disk/by-id/ata-HGST_HUS722T2TALA600_WMC6N0L89MU9"
        ];
      };

      boot.initrd.systemd.services.zfs-import-zroot = {
        preStart = ''
          while [ ! -f ${config.clan.core.vars.generators.zfs.files.key.path} ]; do
            sleep 1
          done
        '';
        unitConfig = {
          StartLimitIntervalSec = 0;
        };
        serviceConfig = {
          RestartSec = "1s";
          Restart = "on-failure";
        };
      };

      disko.devices = {
        disk = {
          x = mirrorBoot "ata-HGST_HUS726020ALE610_K5HEJXVD";
          y = mirrorBoot "ata-HGST_HUS722T2TALA600_WMC6N0L89MU9";
        };
        zpool = {
          zroot = {
            type = "zpool";
            rootFsOptions = {
              compression = "lz4";
              acltype = "posixacl";
              xattr = "sa";
              "com.sun:auto-snapshot" = "true";
              mountpoint = "none";
            };
            datasets = {
              "root" = {
                type = "zfs_fs";
                options = {
                  mountpoint = "none";
                  encryption = "aes-256-gcm";
                  keyformat = "passphrase";
                  keylocation = "file://${config.clan.core.vars.generators.zfs.files.key.path}";
                };
              };
              "root/nixos" = {
                type = "zfs_fs";
                options.mountpoint = "/";
                mountpoint = "/";
              };
              "root/home" = {
                type = "zfs_fs";
                options.mountpoint = "/home";
                mountpoint = "/home";
              };
              "root/tmp" = {
                type = "zfs_fs";
                mountpoint = "/tmp";
                options = {
                  mountpoint = "/tmp";
                  sync = "disabled";
                };
              };
            };
          };
        };
      };
    };
  }