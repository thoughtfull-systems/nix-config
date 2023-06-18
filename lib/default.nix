inputs: rec {
  callAllWithInputs = fs : map (f: callWithInputs f) fs;
  callWithInputs = f :
    { pkgs, ... }@args:
    (if builtins.isPath f then import f else f)
      (args // {
        inherit inputs;
        lib = args.lib // {
          inherit callWithInputs callAllWithInputs;
        };
      });
  forAllSystems = inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed;
  thoughtfullSystem = import ./thoughtfull-system inputs;
}
