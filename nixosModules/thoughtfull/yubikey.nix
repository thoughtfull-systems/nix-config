{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-manager-qt
    yubioath-desktop
  ];
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
}
