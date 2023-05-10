{ lib, pkgs, thoughtfull, ... } : {
  home.packages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    emacs-all-the-icons-fonts
    source-code-pro
  ];
  programs.emacs = {
    enable = true;
    extraConfig = lib.mkBefore ''
      (require 'use-package)
      (use-package my
        :demand t
        :bind (("C-x b" . my-switch-buffer)
               ("C-x C-b" . my-switch-buffer)))
    '';
    extraPackages = epkgs: with epkgs; [
      my
    ];
    overrides = thoughtfull.epkgs;
  };
}
