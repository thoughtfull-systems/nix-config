unstable: args: {
  imports = [
    ./nix.nix
    (import ./unstable-overlay.nix unstable)
  ];
}
