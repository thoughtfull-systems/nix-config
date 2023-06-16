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
  outputs = { agenix, nixpkgs, ... }@inputs: with nixpkgs.lib; let
    forAllSystems = genAttrs systems.flakeExposed;
  in rec {
    emacsPackages = import ./emacsPackages;
    homeManagerModules = import ./homeManagerModules inputs;
    nixosConfigurations = {
      ziph = let
        system = "x86_64-linux";
      in nixosSystem {
        modules = [
          ./nixos/ziph
          nixosModules.thoughtfull
        ];
        specialArgs = {
          agenix = {
            nixosModule = agenix.nixosModules.default;
            package = agenix.packages.${system}.default;
          };
          thoughtfull = {
            epkgs = import ./epkgs;
            home-manager = import ./home-manager;
          };
        };
        system = system;
      };
    };
    nixosModules = rec {
      default = thoughtfull;
      thoughtfull = import ./nixosModules inputs;
    };
    packages = forAllSystems (system: import ./packages (inputs // {
      nixpkgs = import nixpkgs {
        inherit system;
        # TODO: not sure if I need to worry about config.allowUnfree = true?
      };
    }));
  };
}
