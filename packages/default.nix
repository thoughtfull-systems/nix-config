nixpkgs: {
  brightness = import ./brightness nixpkgs;
  exwm-trampoline = import ./exwm-trampoline nixpkgs;
  keyboard = import ./keyboard nixpkgs;
  mic = import ./mic nixpkgs;
  speaker = import ./speaker nixpkgs;
  yubikey-touch-status = import ./yubikey-touch-detector-status nixpkgs;
}
