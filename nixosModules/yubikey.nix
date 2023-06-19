{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    yubikey-manager-qt
    yubioath-desktop
  ];
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
}
