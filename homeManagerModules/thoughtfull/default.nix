{ ... }: {
  imports = [
    ./clojure-dev.nix
    ./desktop
    ./emacs
    ./emoji.nix
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
    ./yubikey.nix
    ./zsh.nix
  ];
  systemd.user.startServices = "sd-switch";
}
