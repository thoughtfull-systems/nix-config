{ agenix, config, pkgs, unstable, ... }: {
  age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.paul-password.file = ../../secrets/paul-password.age;
  };
  boot = {
    initrd = {
      luks.devices."tatenen-nixos" = {
        device = "/dev/disk/by-partlabel/tatenen-lvm-crypt";
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
    # (agenix.packages.x86_64-linux.default.override {
    #   ageBin = "${unstable.rage}/bin/age";
    # })
    pkgs.age-plugin-yubikey
  ];
  hardware = {
    # gpgSmartcards.enable = true;
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
    hostName = "tatenen";
    networkmanager.enable = true;
  };
  nixpkgs.config.allowUnfree = true;
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
      hashedPassword = "$6$6SHfmUQx2i2CokK6$HV6PTlP4z.1f7iJUss.2qJ.aWsNvhO4mYnxVA29Uzv7DgkTdQ8x1vI2w7xP3HcnGQlLa/XlujrjOZvcMQn2ar.";
    };
  };
}
