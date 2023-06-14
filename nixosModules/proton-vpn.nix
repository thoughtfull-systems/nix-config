{ config, lib, ... }: {
  services = lib.mkDefault {
    openvpn.servers.proton = {
      config = ''
        config ${config.age.secrets.proton.ovpn.path}
        auth-user-pass ${config.age.secrets.proton.txt.path}
      '';
      updateResolvConf = true;
    };
  };
}
