{ config, lib, ... }: {
  config = lib.mkIf config.services.postgresql.enable {
    services.postgresqlBackup = {
      enable = true;
      startAt = lib.mkDefault "*-*-* *:00:00";
    };
  };
}
