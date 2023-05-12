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
  outputs = { nixpkgs, ... }@inputs: with nixpkgs.lib; let
    forAllSystems = genAttrs systems.flakeExposed;
  in rec {
    homeManagerModules = import ./homeManagerModules inputs;
    nixosConfigurations = {
      ziph = nixosSystem {
        modules = [
          ./hosts/ziph
          nixosModules.thoughtfull
        ];
        specialArgs = {
          thoughtfull = {
            epkgs = import ./epkgs;
            home-manager = import ./home-manager;
          };
        };
        system = "x86_64-linux";
      };
    };
    nixosModules = import ./nixosModules inputs;
    packages = forAllSystems (system: import ./packages (inputs // {
      nixpkgs = import nixpkgs {
        inherit system;
        # TODO: not sure if I need to worry about config.allowUnfree = true?
      };
    }));
  };
}
