{ nixpkgs, ... }: let
  notify = nixpkgs.substituteAll {
    dir = "bin";
    isExecutable = true;
    src = ./speaker-status-notify;
    notify = "${nixpkgs.notify-desktop}/bin/notify-desktop";
    status = "${status}/bin/speaker-status";
  };
  pactl = "${nixpkgs.pulseaudio}/bin/pactl";
  status = nixpkgs.substituteAll {
    dir = "bin";
    inherit pactl;
    isExecutable = true;
    src = ./speaker-status;
  };
in nixpkgs.symlinkJoin {
  name = "speaker";
  paths = [
    (nixpkgs.substituteAll {
      dir = "bin";
      isExecutable = true;
      src = ./speaker-volume-lower;
      inherit pactl;
      notify = "${notify}/bin/speaker-status-notify";
    })
    (nixpkgs.substituteAll {
      dir = "bin";
      isExecutable = true;
      src = ./speaker-mute;
      inherit pactl;
      notify = "${notify}/bin/speaker-status-notify";
    })
    (nixpkgs.substituteAll {
      dir = "bin";
      isExecutable = true;
      src = ./speaker-volume-raise;
      inherit pactl;
      notify = "${notify}/bin/speaker-status-notify";
    })
    notify
    status
  ];
}
