# xfce4-power-manager does not seem to support hybrid-sleep, so let logind handle the lid switch
#
# https://forum.xfce.org/viewtopic.php?id=13918
# https://gitlab.xfce.org/xfce/xfce4-power-manager/-/issues/7
{ config, lib, ... }:
lib.mkIf config.services.xserver.desktopManager.xfce.enable {
  home-manager.sharedModules = [
    ({ ... }: {
      config.xfconf.settings.xfce4-power-manager = {
        "xfce4-power-manager/logind-handle-lid-switch" = true;
      };
    })
  ];
  services = {
    logind.lidSwitch = "hybrid-sleep";
  };
}
