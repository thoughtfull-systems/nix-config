{ config, lib, pkgs, ... }: let
  cfg = config.thoughtfull.desktop;
in {
  options.thoughtfull.desktop.enable = lib.mkEnableOption "desktop";
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      flameshot
      notify-desktop
      unstable.obsidian
      unstable.zoom-us
    ];
    fonts.fontconfig.enable = lib.mkForce true;
  };
  imports = [
    ./cinnamon.nix
    ./firefox.nix
    ./xbanish.nix
  ];
}
