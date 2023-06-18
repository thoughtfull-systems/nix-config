home-manager: { pkgs, ... }: {
  environment.systemPackages = [
    pkgs.home-manager
  ];
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
