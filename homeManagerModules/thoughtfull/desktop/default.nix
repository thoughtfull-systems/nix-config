{ config, lib, osConfig, pkgs, ... }: let
  cfg = config.thoughtfull.desktop;
in {
  options.thoughtfull.desktop.enable = lib.mkEnableOption "desktop";
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      flameshot
      notify-desktop
      tor-browser-bundle-bin
      unstable.obsidian
      # current version of zoom fails to download
      # unstable.zoom-us
      zoom-us
    ];
    fonts.fontconfig.enable = lib.mkForce true;
    services.blueman-applet.enable = lib.mkDefault osConfig.hardware.bluetooth.enable;
  };
  imports = [
    ./cinnamon.nix
    ./firefox.nix
    ./xbanish.nix
    ./xfce.nix
  ];
}
