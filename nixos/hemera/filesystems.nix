{ ... }: {
  boot.initrd.luks.devices.secure = {
    device = "/dev/disk/by-uuid/b2edd8a5-48ae-4fa0-b539-9ecc6c095190";
    preLVM = true;
  };
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
  swapDevices = [ { device = "/dev/disk/by-uuid/32f36738-8930-46ae-8847-9f811219075a"; } ];
}
