{ inputs, lib, ...}: {
  imports = lib.callAllWithInputs [
    ./agenix.nix
    ./avahi.nix
    ./brother.nix
    ./desktop.nix
    ./fonts.nix
    ./git.nix
    ./home-manager.nix
    ./moonlander.nix
    ./nix.nix
    ./proton-vpn.nix
    ./restic.nix
    ./sudo.nix
    ./thoughtfull-overlay.nix
    ./tt-rss.nix
    ./unstable-overlay.nix
    ./vaultwarden.nix
    ./yubikey.nix
    ./zsh.nix
  ];
  users.mutableUsers = false;
}
