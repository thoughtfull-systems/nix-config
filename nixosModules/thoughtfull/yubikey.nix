{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    age-plugin-yubikey
    yubikey-manager
    yubikey-manager-qt
    yubioath-flutter
  ];
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
}
