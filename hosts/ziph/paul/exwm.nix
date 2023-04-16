{ lib, pkgs, ... }: {
  home = {
    packages = [
      (pkgs.concatTextFile {
        name = "exwm";
        files = [ ./exwm.sh ];
        executable = true;
        destination = "/bin/exwm";
      })
    ];
  };
  xsession = {
    enable = true;
    initExtra = lib.mkAfter "[ ! -f $\{HOME}/.noexwm ] && (exwm; xfce4-session-logout -fl) &";
  };
}
