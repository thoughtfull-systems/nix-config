{ thoughtfull, ... }: {
  home-manager.users.root.imports = [ ../../home/ziph/root.nix ];
  imports = [ thoughtfull.root ];
}
