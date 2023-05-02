{ ... } : {
  home-manager = {
    users.paul = {
      home = {
        username = "paul";
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
      };
      imports = [
        ../zsh.nix
        ./exwm.nix
      ];
      programs = {
        emacs = {
          enable = true;
          extraPackages = epkgs: with epkgs; [
            exwm
          ];
        };
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
      };
    };
  };
}
