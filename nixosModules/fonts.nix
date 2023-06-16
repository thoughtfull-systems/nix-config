{ config, lib, pkgs, ... }: lib.mkIf config.thoughtfull.desktop.enable {
  fonts = {
    enableDefaultFonts = true;
    fontconfig = {
      enable = true;
    };
  };
}
