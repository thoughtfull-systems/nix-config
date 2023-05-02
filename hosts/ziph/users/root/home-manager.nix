{ home-manager, pkgs, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.root = {
      home = {
        username = "root";
        homeDirectory = "/root";
        # This value determines the Home Manager release that your
        # configuration is compatible with. This helps avoid breakage
        # when a new Home Manager release introduces backwards
        # incompatible changes.
        #
        # You can update Home Manager without changing this value. See
        # the Home Manager release notes for a list of state version
        # changes in each release.
        stateVersion = "22.11";
      };
      imports = [ ../zsh.nix ];
      programs = {
        emacs.enable = true;
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
      };
    };
  };
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
