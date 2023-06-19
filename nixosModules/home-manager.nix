{ lib, ... }: {
  home-manager = {
    useGlobalPkgs = lib.mkDefault true;
    useUserPackages = lib.mkDefault true;
    sharedModules = [ ../homeManagerModules ];
  };
}
