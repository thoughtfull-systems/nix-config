{ config, lib, pkgs, ... }: let
  cfg = config.thoughtfull.brother;
in {
  options.thoughtfull.brother.enable = lib.mkEnableOption "brother";
  config = lib.mkIf cfg.enable {
    hardware = {
      printers.ensurePrinters = [
        {
          name = "brother-mfc-l2750dw";
          deviceUri = "ipp://brother.lan:631/";
          model = "everywhere";
          ppdOptions = {
            PageSize = "Letter";
          };
        }
      ];
    };
    services = {
      printing = {
        enable = true;
        drivers = [ pkgs.cups-brother-mfcl2750dw ];
      };
    };
  };
}
