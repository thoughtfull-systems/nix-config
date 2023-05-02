{ home-manager, pkgs, ... } : {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
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
      imports = [ ./exwm.nix ];
      programs = {
        emacs = {
          enable = true;
          extraPackages = epkgs: with epkgs; [
            exwm
          ];
        };
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
        zsh = {
          autocd = true;
          enable = true;
          enableAutosuggestions = true;
          enableCompletion = true;
          enableSyntaxHighlighting = true;
          defaultKeymap = "emacs";
          dirHashes = {
            h = "$HOME";
            e = "$HOME/.config/emacs";
            s = "$HOME/src";
          };
          history = {
            # Include timing information in history
            extended = true;
            ignoreDups = true;
            share = false;
          };
          initExtra = ''
            unalias run-help
            autoload run-help

            ## Configuration
            # allow using hash dirs with out a ~ prefix
            setopt CDABLE_VARS
            # corrections based on Dvorak keyboard
            setopt DVORAK
            # immediately append commands to history
            setopt INC_APPEND_HISTORY_TIME
          '';
          shellAliases = {
            help = "run-help";
            # rerun last command piped to less
            l = "fc -e- | less";
          };
        };
      };
    };
  };
  imports = [
    home-manager.nixosModules.home-manager
  ];
}
