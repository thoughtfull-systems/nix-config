inputs: args: let
  # TODO: not really happy with this hack, but _module.args is bewildering
  import' = f: { pkgs, ... }@args: import f (args // { inherit inputs; });
  importAll' = fs: map (f: import' f) fs;
in {
  imports = importAll' [
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
