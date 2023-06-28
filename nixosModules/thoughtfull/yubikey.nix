{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    age-plugin-yubikey
    yubikey-manager
    yubikey-manager-qt
  ] ++
  (if pkgs ? yubioath-flutter
   then
     # 23.05+
     [ yubioath-flutter ]
   else
     # 22.11
     [ yubioath-desktop ]);
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
}
