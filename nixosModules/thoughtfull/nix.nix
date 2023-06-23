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
  options.thoughtfull.autoUpgrade = {
    flake = lib.mkOption {
      default = "github:thoughtfull-systems/nixfiles/main";
      description = lib.mdDoc "Flake used for automatic upgrades.";
      type = lib.types.str;
    };
    inputs = lib.mkOption {
      default = [ "nixpkgs" ];
      description = lib.mdDoc "Flake inputs to update for upgrades.";
      type = lib.types.listOf lib.types.str;
    };
  };
  config = {
    nix = {
      gc = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault "03:15";
        options = lib.mkDefault "--delete-older-than 7d";
      };
      optimise = {
        automatic = lib.mkDefault true;
        dates = [ "04:15" ];
      };
      settings = {
        auto-optimise-store = lib.mkDefault true;
        experimental-features = [ "flakes" "nix-command" ];
      };
    };
    system.autoUpgrade = {
      allowReboot = lib.mkDefault (!config.thoughtfull.desktop.enable);
      enable = lib.mkDefault true;
      flags = [ "--no-write-lock-file" ] ++
              (map (i: "--update-input ${i}") cfg.inputs);
      flake = cfg.flake;
    };
  };
}
