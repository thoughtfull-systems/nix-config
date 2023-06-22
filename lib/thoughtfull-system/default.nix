inputs: args: inputs.nixpkgs.lib.nixosSystem (args // {
  modules = [
    (import ./overlay-thoughtfull.nix inputs)
    inputs.self.nixosModules.thoughtfull
  ] ++ args.modules;
})
