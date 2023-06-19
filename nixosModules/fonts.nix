{ config, lib, ... }: lib.mkIf config.thoughtfull.desktop.enable {
  fonts = {
    enableDefaultFonts = true;
    fontconfig.enable = true;
  };
}
