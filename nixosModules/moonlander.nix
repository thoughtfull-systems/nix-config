{ config, lib, pkgs, ... } : let
  cfg = config.thoughtfull.moonlander;
in {
  options.thoughtfull.moonlander.enable = lib.mkEnableOption "moonlander";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wally-cli
    ];
    services.xserver.layout = lib.mkForce "us";
  };
}
