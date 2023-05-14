{ lib, pkgs, ... }: {
  imports = [ ../emacs.nix ];
  programs.emacs = {
    extraConfig = ''
      (use-package my-completion)
    '';
    extraPackages = epkgs: with epkgs; [
      my-completion
    ];
  };
}
