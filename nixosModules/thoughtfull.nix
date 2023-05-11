inputs: args: {
  _module.args = { inherit inputs; };
  imports = [
    ./nix.nix
    ./thoughtfull-overlay.nix
    ./unstable-overlay.nix
  ];
}
