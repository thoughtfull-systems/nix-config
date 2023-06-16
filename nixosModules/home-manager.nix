{ inputs, lib, pkgs, ... } : {
  environment.systemPackages = [ pkgs.home-manager ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ (lib.callWithInputs ../homeManagerModules) ];
  };
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
}
