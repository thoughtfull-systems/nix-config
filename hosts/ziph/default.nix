{ agenix, config, pkgs, unstable, ... }: {
  age = {
    identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
    secrets.paul-password.file = ../../age/secrets/paul-password.age;
  };
  boot = {
    initrd = {
      luks.devices."ziph-nixos" = {
        device = "/dev/disk/by-partlabel/ziph-luks";
        preLVM = true;
      };
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
  console.keyMap = "dvorak";
  # environment.systemPackages = [];
  hardware.pulseaudio.enable = false;
  imports = [
    ./hardware-configuration.nix
    ./users
    agenix.nixosModules.default
  ];
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
  networking = {
    domain = "stadig.name";
    hostName = "ziph";
    networkmanager.enable = true;
  };
  nixpkgs.config.allowUnfree = true;
  programs = {
    git.enable = true;
    ssh.startAgent = true;
    zsh.enable = true;
  };
  security.rtkit.enable = true;
  services = {
    pcscd.enable = true;
    openssh.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    printing.enable = true;
    xserver = {
      desktopManager.xfce.enable = true;
      displayManager.autoLogin = {
        enable = true;
        user = "paul";
      };
      enable = true;
      layout = "us";
      xkbOptions = "ctrl:nocaps";
      xkbVariant = "dvorak";
    };
  };
  sound.enable = true;
  system.stateVersion = "22.11"; # Did you read the comment?
  systemd.services = {
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
  };
  time.timeZone = "America/New_York";
  users.mutableUsers = false;
}
