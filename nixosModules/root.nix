{ lib, pkgs, ... } : {
  services.openssh.settings.PermitRootLogin = lib.mkDefault "prohibit-password";
  users.users.root = lib.mkDefault {
    openssh.authorizedKeys.keys = import ./paul/authorizedKeys;
    password = null;
    shell = pkgs.zsh;
  };
}
