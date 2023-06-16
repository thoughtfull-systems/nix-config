{ inputs, pkgs, system, ... } : {
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/tmp/bootstrap.key"
  ];
  imports = [ inputs.agenix.nixosModules.default ];
  environment.systemPackages = [
    inputs.agenix.packages.${system}.default
    pkgs.age-plugin-yubikey
  ];
}
