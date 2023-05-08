{ home-manager, my-elisp, thoughtfull, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit my-elisp thoughtfull;
    };
  };
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
