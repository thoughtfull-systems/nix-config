{ ... }: {
  home-manager.users.root.imports = [ ../../../../home/ziph/root.nix ];
  imports = [ ../../../users/root.nix ];
}
