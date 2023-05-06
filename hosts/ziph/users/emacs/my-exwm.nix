{ lib, pkgs, ... }: {
  home = {
    packages = with pkgs; [
      exwm-trampoline
      flameshot
    ];
    sessionVariables.EDITOR = "emacsclient";
  };
  imports = [ ../emacs.nix ];
  programs.emacs.extraPackages = epkgs: with epkgs; [
    my-exwm
  ];
  xsession = {
    enable = true;
    initExtra = lib.mkAfter "[ ! -f $\{HOME}/.noexwm ] && (exwm-trampoline; xfce4-session-logout -fl) &";
  };
}
