{ pkgs, ... }: {
  systemd.user.services = {
    yubikey-touch-detector = {
      Install.WantedBy = [ "graphical-session.target" ];
      Service.ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector";
      Unit.Wants = [ "yubikey-touch-status.service" ];
    };
    yubikey-touch-status = {
      Install.WantedBy = [ "graphical-session.target" ];
      Service.ExecStart = "${pkgs.thoughtfull.yubikey-touch-status}/bin/yubikey-touch-status";
      Unit = {
        After = [ "yubikey-touch-detector.service" ];
        Requires = [ "yubikey-touch-detector.service" ];
      };
    };
  };
}
