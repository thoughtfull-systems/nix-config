{ thoughtfull, ... }: {
  home-manager.users.paul.imports = [ ../../home/ziph/paul.nix ];
  imports = [ thoughtfull.paul ];
  users.users.paul.hashedPassword = "$6$vUahGtm42AXeeW5s$a1FOSoEWC0c0CGYhF1VrvZapI0bJjEAx/hsi1m8m2b3yHM5eV09carT8SnPa9Vzkf70T5fopiLGfE5T1Wapfb.";
}
