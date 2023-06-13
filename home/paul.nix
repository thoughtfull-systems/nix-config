{ ... } : {
  home = {
    homeDirectory = "/home/paul";
    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "22.11";
    username = "paul";
  };
  imports = [ ./syncthing.nix ];
  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        email = "paul@stadig.name";
        name = "Paul Stadig";
      };
    };
    ignores = [ "*~" ];
  };
}
