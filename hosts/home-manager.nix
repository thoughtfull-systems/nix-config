{ home-manager, my-elisp, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit my-elisp;
    };
  };
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
