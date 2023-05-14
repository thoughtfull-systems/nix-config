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
  imports = [
    ../../homeManagerModules/desktop
    ../../homeManagerModules/emacs/my-completion.nix
    ../../homeManagerModules/emacs/my-exwm.nix
    ../../homeManagerModules/emacs/my-prog.nix
    ../../homeManagerModules/keychain.nix
    ../../homeManagerModules/starship.nix
    ../../homeManagerModules/tmux.nix
    ../../homeManagerModules/zsh.nix
    ./syncthing.nix
  ];
  programs = {
    firefox.enable = true;
    git = {
      enable = true;
      ignores = [ "*~" ];
    };
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };
  thoughtfull.services = {
    syncthing-init.folders = {
      org = {
        devices = [ "hemera" ];
        enable = true;
      };
      org-work = {
        devices = [ "hemera" ];
        enable = true;
      };
      sync = {
        devices = [ "hemera" ];
        enable = true;
      };
    };
    xbanish.enable = true;
  };
}
