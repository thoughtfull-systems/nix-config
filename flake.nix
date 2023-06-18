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
    emacsPackages = import ./emacsPackages;
    homeManagerModules = import ./homeManagerModules inputs;
    lib = rec {
      callAllWithInputs = fs : map (f: callWithInputs f) fs;
      callWithInputs = f :
        { pkgs, ... }@args:
        (if builtins.isPath f then import f else f)
          (args // {
            inherit inputs;
            lib = args.lib // {
              inherit callWithInputs callAllWithInputs;
            };
          });
    };
    nixosConfigurations = {
      ziph = nixosSystem rec {
        modules = [
          (import ./flake/overlay-thoughtfull.nix inputs)
          (import ./flake/overlay-unstable.nix inputs)
          ./nixos/ziph
          nixosModules.thoughtfull
        ];
        specialArgs.system = system;
        system = "x86_64-linux";
      };
    };
    nixosModules = rec {
      default = thoughtfull;
      thoughtfull = lib.callWithInputs ./nixosModules;
    };
    packages = forAllSystems (system: import ./packages (inputs // {
      nixpkgs = import nixpkgs {
        config.allowUnfree = true;
        inherit system;
      };
    }));
  };
}
