self: super: {
  my = self.elpaBuild {
    pname = "my";
    src = ./my.el;
    version = "0.0.0";
  };
}
