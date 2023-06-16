{ config, lib, ... } : let
  cfg = config.thoughtfull.desktop;
in {
  options.thoughtfull.desktop.enable = lib.mkEnableOption "desktop";
  config.home-manager.sharedModules = [({ ... } : {
    thoughtfull.desktop.enable = lib.mkDefault cfg.enable;
  })];
}
