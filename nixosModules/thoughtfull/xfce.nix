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
    xfce.xfce4-panel
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-xkb-plugin
    xfce.xfce4-weather-plugin
  ];
  services = {
    gnome.gnome-keyring.enable = true;
    xserver = {
      desktopManager.xfce = {
        noDesktop = lib.mkDefault true;
        enableXfwm = lib.mkDefault false;
      };
      displayManager.lightdm.enable = true;
    };
    logind.lidSwitch = "ignore";
  };
}
