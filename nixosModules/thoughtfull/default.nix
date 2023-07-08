inputs: { lib, ... }: {
  console.useXkbConfig = lib.mkDefault true;
  hardware.enableAllFirmware = lib.mkDefault true;
  imports = [
    (import ./agenix.nix inputs.agenix)
    (import ./home-manager.nix inputs.home-manager)
    (import ./overlay-unstable.nix inputs.unstable)
    ./avahi.nix
    ./brother.nix
    ./deploy-keys.nix
    ./desktop.nix
    ./fonts.nix
    ./git.nix
    ./moonlander.nix
    ./nix.nix
    ./overlay-thoughtfull.nix
    ./postgresql-backup.nix
    ./proton-vpn.nix
    ./restic.nix
    ./sudo.nix
    ./tt-rss.nix
    ./vaultwarden.nix
    ./xfce.nix
    ./yubikey.nix
    ./zsh.nix
  ];
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  networking.domain = lib.mkDefault "stadig.name";
  nixpkgs.config.allowUnfree = true;
  programs = {
    git.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
  };
  services = {
    openssh.enable = lib.mkDefault true;
    xserver = {
      layout = lib.mkDefault "dvorak";
      xkbOptions = lib.mkDefault "ctrl:nocaps";
    };
  };
  users.mutableUsers = lib.mkDefault false;
}
