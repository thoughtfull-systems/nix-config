{ lib, pkgs, ... } : {
  security.sudo = lib.mkDefault {
    execWheelOnly = true;
    extraConfig = "Defaults timestamp_type=global,timestamp_timeout=-1";
  };
  systemd.services.sudo-reset = lib.mkDefault {
    description = "Reset sudo timeout upon resume from sleep";
    partOf = [ "post-resume.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c 'rm -f /run/sudo/ts/*'";
      RemainAfterExit = "yes";
      Type = "oneshot";
    };
    wantedBy = [ "post-resume.target" ];
  };
}
