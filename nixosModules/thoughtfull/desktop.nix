{ config, lib, ... }: let
  cfg = config.thoughtfull.desktop;
in {
  options.thoughtfull.desktop.enable = lib.mkEnableOption "desktop";
  config = {
    hardware.pulseaudio.enable = lib.mkDefault cfg.enable;
    home-manager.sharedModules = [({ ... }: {
      thoughtfull.desktop.enable = lib.mkDefault cfg.enable;
    })];
    networking.networkmanager.enable = lib.mkDefault cfg.enable;
    security.rtkit.enable = lib.mkDefault config.hardware.pulseaudio.enable;
    services = {
      printing.enable = lib.mkDefault cfg.enable;
      xserver = {
        desktopManager.xfce.enable = lib.mkDefault cfg.enable;
        displayManager = {
          autoLogin = {
            enable = lib.mkDefault cfg.enable;
            user = lib.mkIf (cfg.enable && config.users.users ? paul) (lib.mkDefault "paul");
          };
          lightdm.enable = lib.mkDefault cfg.enable;
        };
        enable = lib.mkDefault cfg.enable;
      };
    };
    time.timeZone = lib.mkIf (cfg.enable) (lib.mkDefault "America/New_York");
  };
}
