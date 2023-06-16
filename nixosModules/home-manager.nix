{ inputs, pkgs, ... } : {
  environment.systemPackages = [ pkgs.home-manager ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ (import ../homeManagerModules inputs) ];
  };
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
}
