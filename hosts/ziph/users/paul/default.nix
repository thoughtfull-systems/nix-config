{ config, pkgs, ... } : {
  home-manager.users.paul = {
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
      ../zsh.nix
      ./exwm.nix
    ];
    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
  users.users.paul = {
    description = "Paul Stadig";
    extraGroups = [ "networkmanager" "wheel" ];
    group = "users";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAB2hfargabOYq6TZ+U6zXUZG+SWrxWdV0Fq5AbhDLghAL4kdwi1j5Q9C8ki622ZwIkk+v7+575IXgyezlHIHjIFFwDf09ODfTPVSwNizpRBK8uMX1YV0XpULJmV8nOJFF0gbn9gQNktM6Obfuhl7QBGhmpEvnvROsBaAqU8OqcQeMRg+w== paul@carbon"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4ztYeWkCSPNWnSxiqxx49qeP1uzibyj15rRCWgoLJb paul@hemera.stadig.name"
    ];
    passwordFile = config.age.secrets.paul-password.path;
    shell = pkgs.zsh;
    uid = 1000;
  };
}
