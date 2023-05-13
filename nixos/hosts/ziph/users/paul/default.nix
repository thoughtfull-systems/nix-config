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
    ../desktop
    ../emacs/my-completion.nix
    ../emacs/my-exwm.nix
    ../emacs/my-prog.nix
    ../keychain.nix
    ../starship.nix
    ../syncthing.nix
    ../tmux.nix
    ../zsh.nix
  ];
  programs = {
    git = {
      enable = true;
      ignores = [ "*~" ];
    };
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };
  thoughtfull.services.syncthing-init.folders = {
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
}
