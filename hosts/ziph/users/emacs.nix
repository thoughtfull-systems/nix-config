{ my-elisp, pkgs, ... } : {
  home.packages = with pkgs; [ source-code-pro ];
  fonts.fontconfig.enable = true;
  programs.emacs = {
    enable = true;
    extraConfig = ''
      (use-package my :demand t)
    '';
    extraPackages = epkgs: with epkgs; [
      my
      use-package
    ];
    overrides = my-elisp;
  };
}
