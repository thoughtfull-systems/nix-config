self: super: {
  my-exwm = self.elpaBuild {
    packageRequires = with self; [
      exwm
      exwm-modeline
    ];
    pname = "my-exwm";
    src = ./my-exwm.el;
    version = "0.0.0";
  };
}
