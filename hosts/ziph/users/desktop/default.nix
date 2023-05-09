{ pkgs, ... }: {
  imports = [
    ./firefox.nix
    ./xbanish.nix
  ];
}
