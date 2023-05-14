inputs: args: let
  # TODO: not really happy with this hack, but _module.args is bewildering
  import' = f: { pkgs, ... }@args: import f (args // { inherit inputs; });
  importAll' = fs: map (f: import' f) fs;
in {
  imports = importAll' [
    ./desktop
    ./emacs/my-completion.nix
    ./emacs/my-exwm.nix
    ./emacs/my-prog.nix
    ./emacs.nix
    ./emacs-overlay.nix
    ./gnome-terminal.nix
    ./home-manager.nix
    ./keychain.nix
    ./starship.nix
    ./syncthing.nix
    ./tmux.nix
    ./zsh.nix
  ];
}
