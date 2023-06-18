agenix: { pkgs, ... } : {
  environment.systemPackages = [
    agenix.packages.${pkgs.system}.default
    pkgs.age-plugin-yubikey
  ];
  imports = [
    agenix.nixosModules.default
  ];
}
