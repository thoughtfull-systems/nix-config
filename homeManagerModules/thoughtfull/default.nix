{ ... }: {
  imports = [
    ./clojure-dev.nix
    ./desktop
    ./emacs
    ./exwm.nix
    ./git.nix
    ./gnome-terminal.nix
    ./home-manager.nix
    ./keychain.nix
    ./notifications.nix
    ./overlay-emacs.nix
    ./starship.nix
    ./syncthing.nix
    ./tmux.nix
    ./yabar.nix
    ./zsh.nix
  ];
}