{ inputs, pkgs, thoughtfull, ... } : {
  environment.systemPackages = [ pkgs.home-manager ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit thoughtfull;
    };
    sharedModules = [ (import ../homeManagerModules inputs) ];
  };
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
}
