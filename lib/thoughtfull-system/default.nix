inputs: args: inputs.nixpkgs.lib.nixosSystem (args // {
  modules = [
    inputs.self.nixosModules.thoughtfull
  ] ++ args.modules;
})
