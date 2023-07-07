{ pkgs, thoughtfull, ... }: {
  boot = {
    initrd = {
      availableKernelModules = [
        "sd_mod"
        "usb_storage"
      ];
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
  hardware = {
    acpilight.enable = true;
    enableAllFirmware = true;
    ledger.enable = true;
    opengl.enable = true;
    pulseaudio.enable = true;
  };
  imports = [
    ./filesystems.nix
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
    gnupg.agent.enable = true;
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
    trezord.enable = true;
    xserver = {
      desktopManager.xfce.enable = true;
      displayManager = {
        autoLogin = {
          enable = true;
          user = "paul";
        };
        lightdm.enable = true;
      };
      enable = true;
      layout = "dvorak";
      xkbOptions = "ctrl:nocaps";
    };
  };
  sound.enable = true;
  time.timeZone = "America/New_York";
  users.mutableUsers = false;
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
