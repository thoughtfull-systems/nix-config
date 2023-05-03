{ lib, pkgs, ... }: {
  imports = [ ../emacs.nix ];
  programs.emacs = {
    extraConfig = ''
      (use-package magit :bind ("C-x g" . magit-status))
      (use-package my-prog :after prog-mode)
    '';
    extraPackages = epkgs: with epkgs; [
      magit
      my-prog
    ];
  };
}
