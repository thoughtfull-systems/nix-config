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
  outputs = { nixpkgs, ... }@inputs: rec {
    emacsPackages = import ./emacsPackages;
    homeManagerModules = import ./homeManagerModules inputs;
    lib = import ./lib inputs;
    nixosConfigurations = {
      ziph = lib.thoughtfullSystem {
        modules = [ ./nixos/ziph ];
        system = "x86_64-linux";
      };
    };
    nixosModules = rec {
      default = thoughtfull;
      thoughtfull = lib.callWithInputs ./nixosModules;
    };
    packages = lib.forAllSystems (system:
      import ./packages (inputs // {
        nixpkgs = import nixpkgs {
          config.allowUnfree = true;
          inherit system;
        };
      })
    );
  };
}
