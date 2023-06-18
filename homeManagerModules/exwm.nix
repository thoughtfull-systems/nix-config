{ config, lib, pkgs, ... }: let
  cfg = config.thoughtfull.exwm;
  desktop = config.thoughtfull.desktop.enable;
in {
  options.thoughtfull.exwm.enable = lib.mkOption {
    default = desktop;
    defaultText = "config.thoughtfull.desktop.enable";
    description = "Whether to enable exwm.";
    type = lib.types.bool;
  };
  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        flameshot
        thoughtfull.exwm-trampoline
      ];
      sessionVariables.EDITOR = "emacsclient";
    };
    programs.emacs.extraPackages = epkgs: with epkgs; [
      my-exwm
    ];
    thoughtfull.emacs.enable = true;
    xsession = {
      enable = true;
      initExtra = lib.mkAfter "[ ! -f $\{HOME}/.noexwm ] && exwm-trampoline &";
    };
  };
}
