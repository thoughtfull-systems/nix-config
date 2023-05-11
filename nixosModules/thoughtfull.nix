inputs: args: {
  _module.args = inputs;
  imports = [
    ./nix.nix
    ./unstable-overlay.nix
  ];
}
