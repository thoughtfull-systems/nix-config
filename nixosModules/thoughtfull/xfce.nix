{ config, lib, pkgs, ... }:
lib.mkIf config.services.xserver.desktopManager.xfce.enable {
  nixpkgs.overlays = [
    (self: super: {
      xfce = super.xfce // {
        xfce4-pulseaudio-plugin = super.xfce.xfce4-pulseaudio-plugin.overrideAttrs (
          (prevAttrs: {
            buildInputs = prevAttrs.buildInputs ++ [
              super.libcanberra
            ];
          }));
      };
    })
  ];
  services = {
    # xfce4-power-manager does not seem to support hybrid-sleep, so let logind handle the lid switch
    #
    # https://forum.xfce.org/viewtopic.php?id=13918
    # https://gitlab.xfce.org/xfce/xfce4-power-manager/-/issues/7
    logind.lidSwitch = "hybrid-sleep";
    picom.enable = true;
    xserver.desktopManager.xfce = {
      # without desktop I get the default X cursor over the panel; not a big deal, but I don't like
      # it
      noDesktop = lib.mkDefault false;
      enableXfwm = lib.mkDefault false;
    };
  };
}
