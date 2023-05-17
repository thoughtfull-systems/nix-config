{ agenix, pkgs, ... } : {
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  imports = [ agenix.nixosModule ];
  environment.systemPackages = [
    agenix.package
    pkgs.age-plugin-yubikey
  ];
}
