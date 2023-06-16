{ inputs, lib, ... }: {
  imports = lib.callAllWithInputs [
    ./desktop
    ./emacs
    ./emacs-overlay.nix
    ./exwm.nix
    ./git.nix
    ./gnome-terminal.nix
    ./home-manager.nix
    ./keychain.nix
    ./starship.nix
    ./syncthing.nix
    ./tmux.nix
    ./zsh.nix
  ];
}
