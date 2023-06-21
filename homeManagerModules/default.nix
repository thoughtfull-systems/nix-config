{ ... }: {
  imports = [
    ./desktop
    ./emacs
    ./emacs-overlay.nix
    ./exwm.nix
    ./git.nix
    ./gnome-terminal.nix
    ./home-manager.nix
    ./keychain.nix
    ./notifications.nix
    ./starship.nix
    ./syncthing.nix
    ./tmux.nix
    ./yabar.nix
    ./zsh.nix
  ];
}
