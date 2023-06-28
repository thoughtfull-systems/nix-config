{ config, lib, pkgs, ... }: let
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
  };
  imports = [
    ./cinnamon.nix
    ./firefox.nix
    ./xbanish.nix
  ];
}
