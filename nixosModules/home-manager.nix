{ inputs, lib, pkgs, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ (lib.callWithInputs ../homeManagerModules) ];
  };
}
