{ ... }: {
  home-manager.users.paul.imports = [ ../../home/ziph/paul.nix ];
  imports = [ ../paul.nix ];
}
