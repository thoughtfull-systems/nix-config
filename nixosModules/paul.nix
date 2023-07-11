{ config, pkgs, ... } : {
  users.users.paul = {
    description = "Paul Stadig";
    extraGroups = [ "networkmanager" "video" "wheel" ];
    group = "users";
    isNormalUser = true;
    openssh.authorizedKeys.keys = import ./paul/authorizedKeys;
    shell = pkgs.zsh;
    uid = 1000;
  };
}
