{ lib, my-elisp, pkgs, ... } : {
  home.packages = with pkgs; [ source-code-pro ];
  programs.emacs = {
    enable = true;
    extraConfig = lib.mkBefore ''
      (require 'use-package)
      (use-package my :demand t)
    '';
    extraPackages = epkgs: with epkgs; [
      my
      use-package
    ];
    overrides = my-elisp;
  };
}
