home-manager: { lib, pkgs, ... }: {
  environment.systemPackages = [
    pkgs.home-manager
  ];
  home-manager = {
    useGlobalPkgs = lib.mkDefault true;
    useUserPackages = lib.mkDefault true;
    sharedModules = [ ../../homeManagerModules ];
  };
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
