{ home-manager, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
