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
        xfce4-power-manager = super.xfce.xfce4-power-manager.overrideAttrs (
          (prevAttrs: {
            patches = [ ./0001-Hybrid-Sleep-v2.2.patch ];
          }));
      };
    })
  ];
  environment.systemPackages = with pkgs; [
    # Since screen saver is disabled, use light-locker for screen locking
    lightlocker
    xfce.xfce4-xkb-plugin
    xfce.xfce4-weather-plugin
  ];
  services = {
    xserver = {
      desktopManager.xfce = {
        # Screensaver and power-manager fight for DPMS (display power management system), the best
        # way to resolve it is disable screensaver.
        enableScreensaver = lib.mkDefault false;
        # Without desktop I get the default X cursor over the panel; not a big deal, but I don't
        # like it
        noDesktop = lib.mkDefault false;
        enableXfwm = lib.mkDefault false;
      };
      displayManager.lightdm.enable = true;
    };
    logind.lidSwitch = "ignore";
  };
}
