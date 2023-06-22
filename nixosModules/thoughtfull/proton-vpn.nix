{ config, lib, ... }: let
  cfg = config.thoughtfull.proton-vpn;
  secrets = config.age.secrets;
in {
  options.thoughtfull.proton-vpn.enable = lib.mkEnableOption "proton-vpn";
  config = lib.mkIf cfg.enable {
    age.secrets = {
      proton-ovpn.file = ../age/secrets/proton-ovpn.age;
      proton-txt.file = ../age/secrets/proton-txt.age;
    };
    services = lib.mkDefault {
      openvpn.servers.proton = {
        config = ''
          config ${secrets.proton-ovpn.path}
          auth-user-pass ${secrets.proton-txt.path}
        '';
        updateResolvConf = true;
      };
    };
  };
}
