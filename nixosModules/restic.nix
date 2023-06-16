{ config, lib, pkgs, ... }: let
  cfg = config.thoughtfull.restic;
  postgres-enabled = config.services.postgresql.enable;
  vaultwarden-enabled = config.services.vaultwarden.enable;
  enabled = postgres-enabled || vaultwarden-enabled;
  pgbackup = config.services.postgresqlBackup;
in {
  options.thoughtfull.restic = {
    s3Bucket = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "Name of S3 bucket to store backups";
    };
    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = lib.mdDoc ''
        file containing the credentials to access the repository, in the format of an
        EnvironmentFile as described by systemd.exec(5)
      '';
    };
    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = lib.mdDoc ''
        Read the repository password from a file.
      '';
    };
  };
  config = lib.mkif enabled {
    assertions = [{
      assertion = postgres-enabled -> pgbackup.enable;
      message = "PostgreSQL is enabled without backups!";
    }];
    environment.systemPackages = [ pkgs.restic ];
    services.restic.backups.default = (lib.mkMerge [
      {
        environmentFile = cfg.environmentFile;
        passwordFile = cfg.passwordFile;
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 75"
        ];
        repository = "s3:s3.amazonaws.com/${cfg.s3Bucket}";
        timerConfig.OnCalendar = lib.mkDefault "*-*-* *:00:00";
      }
      (lib.mkIf postgres-enabled {
        paths = [ pgbackup.location ];
      })
      (lib.mkIf vaultwarden-enabled {
        extraBackupArgs = [
          "--exclude=/var/lib/bitwarden_rs/icon_cache"
          "--exclude=/var/lib/bitwarden_rs/sends"
        ];
        paths = [ "/var/lib/bitwarden_rs" ];
      })
    ]);
  };
}
