{ pkgs, ... } : {
  users.users.root = {
    openssh.authorizedKeys.keys = import ../paul/authorizedKeys;
    shell = pkgs.zsh;
  };
}
