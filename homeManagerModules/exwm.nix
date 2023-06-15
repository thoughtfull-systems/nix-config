{ lib, pkgs, ... }: {
  home = {
    packages = with pkgs; [
      thoughtfull.exwm-trampoline
      flameshot
    ];
    sessionVariables.EDITOR = "emacsclient";
  };
  imports = [ ./emacs ];
  programs.emacs.extraPackages = epkgs: with epkgs; [
    my-exwm
  ];
  thoughtfull.emacs.enable = true;
  xsession = {
    enable = true;
    initExtra = lib.mkAfter "[ ! -f $\{HOME}/.noexwm ] && (exwm-trampoline; xfce4-session-logout -fl) &";
  };
}
