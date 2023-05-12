epkgs: {
  my-exwm = epkgs.elpaBuild {
    packageRequires = with epkgs; [
      exwm
      exwm-modeline
    ];
    pname = "my-exwm";
    src = ./my-exwm.el;
    version = "0.0.0";
  };
}
