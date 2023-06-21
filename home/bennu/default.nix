{ kolide, nix-lib, pkgs, unstable, ... }: {
  boot = {
    initrd = {
      luks.devices.secure = {
        device = "/dev/disk/by-uuid/747e16a2-631a-4d6c-bfed-c7c638858544";
        preLVM = true;
      };
    };
  };
  environment.systemPackages = with pkgs; [
    adapta-gtk-theme
    emacs
    gparted
  ];
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/ac80195b-8acc-43b4-8a4a-30f712d62b2a";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/1210-03F1";
      fsType = "vfat";
    };
  };
  home-manager.extraSpecialArgs = { inherit nix-lib pkgs unstable; };
  imports = [
    ../common/fonts.nix
    ../common/nix.nix
    ../common/yubikey.nix
    ./paul.nix
  ] ++ (with nix-lib.nixosModules; [
    auto-upgrade
    avahi
    git
    nix
    sudo
    zsh
  ]);
  i18n.defaultLocale = "en_US.UTF-8";
  networking = {
    domain = "stadig.name";
    hostName = "bennu";
    networkmanager.enable = true;
  };
  powerManagement.cpuFreqGovernor = "powersave";
  programs = {
    git.lfs.enable = true;
    gnupg.agent.enable = true;
  };
  services = {
    openssh.enable = true;
    printing.enable = true;
    xserver = {
      desktopManager.cinnamon.enable = true;
      displayManager = {
        autoLogin = {
          enable = true;
          user = "paul";
        };
        lightdm.enable = true;
      };
      enable = true;
      layout = "dvorak";
      libinput.enable = true;
      xkbOptions = "ctrl:nocaps";
    };
  };
  sound.enable = true;
  swapDevices = [
    { device = "/dev/disk/by-uuid/bb4dc0da-5d47-427f-a988-4813a3861b64"; }
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
  systemd.services.launcher-kolide-k2 = let
    flagfile = pkgs.writeTextFile {
      name = "launcher.flags";
      text = ''
        with_initial_runner
        control
        autoupdate
        control_hostname k2control.kolide.com
        update_channel stable
        transport jsonrpc
        hostname k2device.kolide.com
        root_directory /var/kolide-k2/k2device.kolide.com
        osqueryd_path ${kolide}/usr/local/kolide-k2/bin/osqueryd
        enroll_secret_path ${kolide}/etc/kolide-k2/secret
      '';
    };
  in {
    description = "The Kolide Launcher";
    after = [ "network.target" "syslog.service" ];
    serviceConfig = {
      ExecStart = "${kolide}/usr/local/kolide-k2/bin/launcher -config ${flagfile}";
      Restart = "on-failure";
      RestartSec = 3;
    };
    wantedBy = [ "multi-user.target" ];
  };
  thoughtfull.moonlander.enable = true;
  virtualisation.docker.enable = true;
}
