{ config, lib, pkgs, ... }: lib.mkIf config.thoughtfull.desktop.enable {
  fonts = {
    enableDefaultFonts = true;
    fonts = [ pkgs.corefonts ];
    fontconfig.enable = true;
  };
}
