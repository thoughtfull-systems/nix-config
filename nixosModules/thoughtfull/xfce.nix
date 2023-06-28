{ config, lib, pkgs, ... }:
lib.mkIf config.services.xserver.desktopManager.xfce.enable {
  environment.systemPackages = [ pkgs.xfce.xfce4-panel ];
  services.xserver.desktopManager.xfce = {
    noDesktop = lib.mkDefault true;
    enableXfwm = lib.mkDefault false;
  };
}
