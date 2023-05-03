self: super: {
  my-prog = self.elpaBuild {
    pname = "my-prog";
    src = ./my-prog.el;
    version = "0.0.0";
  };
}
