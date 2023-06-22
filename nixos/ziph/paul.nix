{ thoughtfull, ... }: {
  home-manager.users.paul.imports = [ ../../home/ziph/paul.nix ];
  imports = [ thoughtfull.paul ];
}
