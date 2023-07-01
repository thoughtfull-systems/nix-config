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
  environment.systemPackages = [
    pkgs.xfce.xfce4-xkb-plugin
    pkgs.xfce.xfce4-weather-plugin
  ];
  services = {
    xserver.desktopManager.xfce = {
      # without desktop I get the default X cursor over the panel; not a big deal, but I don't like
      # it
      noDesktop = lib.mkDefault false;
      enableXfwm = lib.mkDefault false;
    };
  };
}
