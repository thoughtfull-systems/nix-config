{ pkgs, ... }: {
  home.packages = with pkgs; [
    flameshot
  ];
  imports = [
    ./firefox.nix
    ./xbanish.nix
  ];
}
