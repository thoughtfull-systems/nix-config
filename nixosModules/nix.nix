# Table stakes nix configuration:
#   1. Turn on flakes
#   2. Enable nix store optimization
#   3. Enable nix store garbage collection
#   4. Enable autoUpgrade for nixpkgs
#
# For autoUpgrade you must create a deploy key and store it at `/etc/nixos/deploy-key`.  Example:
#   `sudo ssh-keygen -t ed25519 -f /etc/nixos/deploy-key -N "" -C "`hostname` deploy key"`
{ config, lib, ... }: let
  cfg = config.thoughtfull.autoUpgrade;
in {
  options = {
    thoughtfull.autoUpgrade = {
      flake = lib.mkOption {
        default = "git+ssh://git@deploy.github.com/thoughtfull-systems/nix-config?ref=main";
        description = lib.mdDoc "Flake used for automatic upgrades.";
        type = lib.types.str;
      };
      hostname = lib.mkOption {
        default = "github.com";
        description = lib.mdDoc "Hostname prepended with 'deploy.' and configured for deploy key.";
        type = lib.types.str;
      };
      inputs = lib.mkOption {
        default = [ "nixpkgs" ];
        description = lib.mdDoc "Flake inputs to update for upgrades.";
        type = lib.types.listOf lib.types.str;
      };
    };
  };
  config = lib.mkMerge [
    (lib.mkDefault {
      nix = {
        gc = {
          automatic = true;
          dates = "03:15";
          options = "--delete-older-than 7d";
        };
        optimise = {
          automatic = true;
          dates = [ "04:15" ];
        };
        settings = {
          auto-optimise-store = true;
          experimental-features = [ "flakes" "nix-command" ];
        };
      };
      programs.ssh.extraConfig = ''
        Host deploy.${cfg.hostname}
          Hostname ${cfg.hostname}
          IdentityFile "/etc/nixos/deploy-key"
      '';
      system.autoUpgrade = {
        allowReboot = true;
        enable = false;
        flake = cfg.flake;
      };
    })
    # if this is mkDefault it gets lost
    {
      system.autoUpgrade.flags = [
        "--no-write-lock-file"
      ] ++ (map (i: "--update-input ${i}") cfg.inputs);
    }
  ];
}
