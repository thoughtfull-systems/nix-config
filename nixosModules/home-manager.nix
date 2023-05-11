{ inputs, thoughtfull, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit thoughtfull;
    };
  };
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
}
