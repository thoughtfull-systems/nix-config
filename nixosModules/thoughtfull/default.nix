inputs: { ... }: {
  imports = [
    (import ./agenix.nix inputs.agenix)
    ./avahi.nix
    ./brother.nix
    ./deploy-keys.nix
    ./desktop.nix
    ./fonts.nix
    ./git.nix
    ./home-manager.nix
    ./moonlander.nix
    ./nix.nix
    ./postgresql-backup.nix
    ./proton-vpn.nix
    ./restic.nix
    ./sudo.nix
    ./tt-rss.nix
    ./vaultwarden.nix
    ./yubikey.nix
    ./zsh.nix
  ];
  users.mutableUsers = false;
}
