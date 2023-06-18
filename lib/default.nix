inputs: {
  forAllSystems = inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed;
  thoughtfullSystem = import ./thoughtfull-system inputs;
}
