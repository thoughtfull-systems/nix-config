{ ... }: {
  boot.initrd.luks.devices."ziph-nixos" = {
    device = "/dev/disk/by-partlabel/ziph-luks";
    preLVM = true;
  };
  fileSystems = {
    "/" = {
      device = "/dev/mapper/ziph-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/ziph-boot";
      fsType = "vfat";
    };
  };
  swapDevices = [ { device = "/dev/mapper/ziph-swap"; } ];
}
