{ thoughtfull, ... }: {
  home-manager.users.root.imports = [ thoughtfull.home.root ];
  imports = [ thoughtfull.root ];
  users.users.root.password = null;
}
