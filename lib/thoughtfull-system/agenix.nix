agenix: { pkgs, ... } : {
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
  environment.systemPackages = [
    agenix.packages.${pkgs.system}.default
    pkgs.age-plugin-yubikey
  ];
  imports = [
    agenix.nixosModules.default
  ];
}
