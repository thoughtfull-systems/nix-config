{ lib, pkgs, ... }: {
  imports = [ ../emacs.nix ];
  programs.emacs = {
    extraConfig = ''
      (use-package my-prog :after prog-mode)
    '';
    extraPackages = epkgs: with epkgs; [
      my-prog
      paredit
    ];
  };
}
