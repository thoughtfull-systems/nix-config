{ pkgs, thoughtfull, ... }: {
  boot = {
    initrd = {
      availableKernelModules = [
        "sd_mod"
        "usb_storage"
      ];
      luks.devices.secure = {
        device = "/dev/disk/by-uuid/b2edd8a5-48ae-4fa0-b539-9ecc6c095190";
        preLVM = true;
      };
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
  console.useXkbConfig = true;
  environment.systemPackages = with pkgs; [
    adapta-gtk-theme
    anki-bin
    firefox
    gparted
    monero-gui
    unstable.ledger-live-desktop
    virt-manager
  ];
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/75fc9a6f-3ebc-4cf1-b588-89edde2574d7";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/BC8B-B321";
      fsType = "vfat";
    };
  };
  hardware = {
    acpilight.enable = true;
    enableAllFirmware = true;
    ledger.enable = true;
    opengl.enable = true;
    pulseaudio.enable = true;
  };
  imports = [
    ./hardware-configuration.nix
    ./paul.nix
    ./root.nix
    thoughtfull.thoughtfull
  ];
  i18n.defaultLocale = "en_US.UTF-8";
  networking = {
    domain = "stadig.name";
    hostName = "hemera";
    networkmanager.enable = true;
  };
  nixpkgs.config.allowUnfree = true;
  programs = {
    gnupg.agent = {
      enable = true;
    };
    ssh.extraConfig = ''
      Host *.local
        ForwardAgent yes
      Host raspi3b.lan
        ForwardAgent Yes
        Hostname raspi3b.lan
        User root
      Host raspi3b
        ForwardAgent Yes
        Hostname raspi3b.lan
        RemoteCommand tmux att
        RequestTTY yes
        User root
      Host raspi3b.unlock
        ForwardAgent Yes
        Hostname raspi3b.lan
        Port 222
        RemoteCommand cryptsetup-askpass
        RequestTTY yes
        User root
    '';
  };
  services = {
    openssh.enable = true;
    printing.enable = true;
    # supposedly a fix for CPU throttling on Lenovo/Intel, but it given an error
    # saying that my CPU is not supported
    #
    # throttled.enable = true;
    trezord.enable = true;
    xserver = {
      desktopManager.xfce.enable = true;
      displayManager = {
        autoLogin = {
          enable = true;
          user = "paul";
        };
        lightdm.enable = true;
        # This is for running a VM on a second X display.  I was able to get X
        # to run, but the cinnamon session then gets wedged.  Still more to
        # figure out ...
        # startx.enable = true;
      };
      enable = true;
      layout = "dvorak";
      xkbOptions = "ctrl:nocaps";
    };
  };
  sound.enable = true;
  swapDevices = [
    { device = "/dev/disk/by-uuid/32f36738-8930-46ae-8847-9f811219075a"; }
  ];
  time.timeZone = "America/New_York";
  users = {
    mutableUsers = false;
    users.root.password = null;
  };
  system = {
    autoUpgrade = {
      allowReboot = false;
      dates = "12:00";
    };
    stateVersion = "22.05";
  };
  thoughtfull.desktop.enable = true;
  virtualisation.libvirtd.enable = true;
}
