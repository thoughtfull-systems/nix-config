{ ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ ../homeManagerModules ];
  };
}
