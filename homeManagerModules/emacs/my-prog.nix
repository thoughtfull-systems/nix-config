{ lib, pkgs, ... }: {
  home.packages = with pkgs; [
    silver-searcher
    # for loading files from JARs
    unzip
  ];
  imports = [ ../emacs.nix ];
  programs.emacs = {
    extraConfig = ''
      (require 'use-package)
      (use-package my-prog)
    '';
    extraPackages = epkgs: with epkgs; [
      my-prog
    ];
  };
}
