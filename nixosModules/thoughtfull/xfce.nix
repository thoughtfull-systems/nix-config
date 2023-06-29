{ config, lib, pkgs, ... }:
lib.mkIf config.services.xserver.desktopManager.xfce.enable {
  services.xserver.desktopManager.xfce = {
    # without desktop I get the default X cursor over the panel; not a big deal, but I don't like it
    noDesktop = lib.mkDefault false;
    enableXfwm = lib.mkDefault false;
  };
}
