{ lib, pkgs, ... }: {
  imports = [ ../emacs.nix ];
  programs.emacs = {
    extraConfig = ''
      (use-package my-prog)
    '';
    extraPackages = epkgs: with epkgs; [
      my-prog
    ];
  };
}
