{ ... }: {
  home-manager.users.paul.imports = [ ../../../../home/ziph/paul.nix ];
  imports = [ ../../../users/paul.nix ];
}
