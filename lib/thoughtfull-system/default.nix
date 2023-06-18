inputs: args: inputs.nixpkgs.lib.nixosSystem (args // {
  modules = [
    (import ./agenix.nix inputs.agenix)
    (import ./overlay-thoughtfull.nix inputs)
    (import ./overlay-unstable.nix inputs.unstable)
    (import ./home-manager.nix inputs.home-manager)
    inputs.self.nixosModules.thoughtfull
  ] ++ args.modules;
})
