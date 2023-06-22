inputs: { ... }: {
  imports = [
    (import ./agenix.nix inputs.agenix)
    (import ./home-manager.nix inputs.home-manager)
    ./avahi.nix
    ./brother.nix
    ./deploy-keys.nix
    ./desktop.nix
    ./fonts.nix
    ./git.nix
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
