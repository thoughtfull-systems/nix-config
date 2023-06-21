{ nixpkgs, ... }: let
  xbacklight = "${nixpkgs.xorg.xbacklight}/bin/xbacklight";
  status = nixpkgs.substituteAll {
    dir = "bin";
    inherit xbacklight;
    isExecutable = true;
    src = ./brightness-status;
  };
  notify = nixpkgs.substituteAll {
    dir = "bin";
    isExecutable = true;
    src = ./brightness-status-notify;
    notify = "${nixpkgs.notify-desktop}/bin/notify-desktop";
    status = "${status}/bin/brightness-status";
  };
in nixpkgs.symlinkJoin {
  name = "brightness";
  paths = [
    status
    notify
    (nixpkgs.substituteAll {
      dir = "bin";
      isExecutable = true;
      src = ./brightness-up;
      inherit xbacklight;
      notify = "${notify}/bin/brightness-status-notify";
    })
    (nixpkgs.substituteAll {
      dir = "bin";
      isExecutable = true;
      src = ./brightness-down;
      inherit xbacklight;
      notify = "${notify}/bin/brightness-status-notify";
    })
  ];
}
