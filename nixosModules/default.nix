inputs: rec {
  default = thoughtfull;
  home = inputs.self.homeManagerModules;
  paul = import ./paul.nix;
  thoughtfull = import ./thoughtfull inputs;
  root = import ./root.nix;
}
