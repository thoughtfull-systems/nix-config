{ home-manager, thoughtfull, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit thoughtfull;
    };
  };
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
