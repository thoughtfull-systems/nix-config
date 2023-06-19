{ config, lib, pkgs, ... }: lib.mkIf config.services.tt-rss.enable {
  environment.systemPackages = with pkgs; [
    # needed for database migrations
    php
  ];
  networking.firewall.allowedTCPPorts = [ 80 ];
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [ "tt_rss" ];
      ensureUsers = [
        {
          name = "tt_rss";
          ensurePermissions = {
            "DATABASE tt_rss" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    postgresqlBackup.databases = [ "tt_rss" ];
    tt-rss = {
      database = {
        createLocally = false;
      };
      # must be set in system config
      # email = {
      #   fromAddress = "example@example.com";
      #   fromName = "example";
      # };
      registration = {
        enable = true;
      };
      # must be set in system config
      # selfUrlPath = "https://www.example.com";
    };
  };
}
