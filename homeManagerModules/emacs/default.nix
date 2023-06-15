{ config, lib, pkgs, ... } : let
  cfg = config.thoughtfull.emacs;
in {
  options.thoughtfull.emacs.enable = lib.mkEnableOption "emacs";
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      emacs-all-the-icons-fonts
      silver-searcher
      source-code-pro
      # for loading files from JARs
      unzip
    ];
    programs.emacs = {
      enable = true;
      extraConfig = lib.mkBefore (builtins.readFile ./init.el);
      extraPackages = epkgs: with epkgs; [
        my
        my-completion
        my-prog
      ];
    };
  };
}
