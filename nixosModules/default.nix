inputs: rec {
  default = thoughtfull;
  paul = import ./paul.nix;
  thoughtfull = import ./thoughtfull inputs;
  root = import ./root.nix;
}
