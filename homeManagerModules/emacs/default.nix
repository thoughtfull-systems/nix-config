{ config, lib, pkgs, ... } : let
  cfg = config.thoughtfull.emacs;
in {
  options.thoughtfull.emacs.enable = lib.mkEnableOption "emacs";
  config = lib.mkIf cfg.enable {
    home = {
      file.".config/emacs/init.el".source = ./init.el;
      packages = with pkgs; [
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
    };
    programs.emacs = {
      enable = true;
      extraPackages = epkgs: with epkgs; [
        my
        my-completion
        my-prog
      ];
    };
  };
}
