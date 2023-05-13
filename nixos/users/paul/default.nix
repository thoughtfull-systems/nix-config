{ config, pkgs, ... } : {
  users.users.paul = {
    description = "Paul Stadig";
    extraGroups = [ "networkmanager" "wheel" ];
    group = "users";
    isNormalUser = true;
    openssh.authorizedKeys.keys = import ./authorizedKeys;
    passwordFile = config.age.secrets.paul-password.path;
    shell = pkgs.zsh;
    uid = 1000;
  };
}
