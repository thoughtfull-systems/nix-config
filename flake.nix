{
  description = "NixOS configuration";
  inputs = {
    agenix.url = "github:ryantm/agenix/e64961977f60388dd0b49572bb0fc453b871f896";
    hardware.url = "github:nixos/nixos-hardware/master";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-22.11";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    # for some software I want the most recent version
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = inputs: {
    nixosConfigurations = {
      ziph = let
        system = "x86_64-linux";
        unstable = import inputs.unstable {
          config.allowUnfree = true;
          system = system;
        };
      in
        inputs.nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/ziph ];
          specialArgs = {
            inherit (inputs) agenix home-manager;
            thoughtfull = {
              epkgs = import ./epkgs unstable;
              home-manager = import ./home-manager;
              pkgs = import ./pkgs;
            };
            unstable = unstable;
          };
          system = system;
        };
    };
  };
}
