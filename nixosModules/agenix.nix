{ agenix, pkgs, ... } : {
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/nixos/age/yk5nano475.txt"
  ];
  nixpkgs.overlays = [
    (self: super: {
      rage = super.rage // super.age-plugin-yubikey;
    })
  ];
  imports = [ agenix.nixosModule ];
  environment.systemPackages = [
    agenix.package
    pkgs.age-plugin-yubikey
  ];
}
