{ lib, pkgs, ... } : {
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
    extraPackages = epkgs: with epkgs; [
      my
    ];
  };
}
