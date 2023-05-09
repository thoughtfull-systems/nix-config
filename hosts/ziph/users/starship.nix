{ pkgs, ... }: {
  home.packages = with pkgs; [ starship ];
  programs = {
    zsh.initExtra = ''
      eval "$(starship init zsh)"
    '';
  };
}
