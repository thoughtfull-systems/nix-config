{ agenix, config, pkgs, unstable, ... }: {
  age = {
    identityPaths = [ "/tmp/bootstrap.key" ];
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
  environment.systemPackages = [
    # ?? pkgs.age-plugin-yubikey
  ];
  hardware = {
    pulseaudio.enable = false;
  };
  imports = [
    ./hardware-configuration.nix
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
    zsh.enable = true;
  };
  security.rtkit.enable = true;
  services = {
    pcscd.enable = true;
    openssh.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    printing.enable = true;
    xserver = {
      enable = true;
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "paul";
        gdm.enable = true;
      };
      desktopManager.gnome.enable = true;
      layout = "us";
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
  users = {
    mutableUsers = false;
    users.paul = {
      description = "Paul Stadig";
      extraGroups = [ "networkmanager" "wheel" ];
      isNormalUser = true;
      passwordFile = config.age.secrets.paul-password.path;
    };
  };
}
