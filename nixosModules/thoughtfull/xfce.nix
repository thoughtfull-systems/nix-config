{ config, lib, pkgs, ... }:
lib.mkIf config.services.xserver.desktopManager.xfce.enable {
  services = {
    # xfce4-power-manager does not seem to support hybrid-sleep, so I configure it to let logind
    # handle the lid switch
    logind.lidSwitch = "hybrid-sleep";
    xserver.desktopManager.xfce = {
      # without desktop I get the default X cursor over the panel; not a big deal, but I don't like it
      noDesktop = lib.mkDefault false;
      enableXfwm = lib.mkDefault false;
    };
  };
}
