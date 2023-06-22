inputs: args: inputs.nixpkgs.lib.nixosSystem (args // {
  modules = [
    (import ./overlay-thoughtfull.nix inputs)
    (import ./overlay-unstable.nix inputs.unstable)
    inputs.self.nixosModules.thoughtfull
  ] ++ args.modules;
})
