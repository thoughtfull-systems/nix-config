inputs: args: let
  # TODO: not really happy with this hack, but _module.args is bewildering
  import' = f: { pkgs, ... }@args: import f (args // { inherit inputs; });
  importAll' = fs: map (f: import' f) fs;
in {
  imports = importAll' [
    ./agenix.nix
    ./avahi.nix
    ./brother.nix
    ./git.nix
    ./nix.nix
    ./home-manager.nix
    ./proton-vpn.nix
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
