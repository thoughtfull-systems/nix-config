{ agenix, nixpkgs, self, ... }@inputs: args:
nixpkgs.lib.nixosSystem (args // {
  modules = [
    ({ pkgs, ... } : {
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
    })
    (import ../flake/overlay-thoughtfull.nix inputs)
    (import ../flake/overlay-unstable.nix inputs)
    self.nixosModules.thoughtfull
  ] ++ args.modules;
})
