{ pkgs, ... }: {
  home.packages = with pkgs; [
    flameshot
    notify-desktop
  ];
  imports = [
    ./firefox.nix
    ./xbanish.nix
  ];
}
