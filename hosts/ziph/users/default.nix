{ ... } : {
  imports = [
    ../../home-manager.nix
    ./paul
    ./root
  ];
  users.mutableUsers = false;
}
