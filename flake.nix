{
  description = "NixOS configuration";
  inputs = {
    agenix.url = "github:thoughtfull-systems/agenix";
    hardware.url = "github:nixos/nixos-hardware/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    # for some software I want the most recent version
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = inputs: {
    nixosConfigurations = {
      tatenen = inputs.nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/tatenen ];
        specialArgs = {
          agenix = inputs.agenix;
          unstable = import inputs.unstable {
            config.allowUnfree = true;
            system = "x86_64-linux";
          };
        };
        system = "x86_64-linux";
      };
    };
  };
}
