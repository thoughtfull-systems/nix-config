self: super: {
  my-prog = self.elpaBuild {
    packageRequires = with self; [
      magit
      paredit
    ];
    pname = "my-prog";
    src = ./my-prog.el;
    version = "0.0.0";
  };
}
