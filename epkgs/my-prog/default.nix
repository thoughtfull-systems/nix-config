self: super: {
  my-prog = self.elpaBuild {
    packageRequires = with self; [
      company
      flycheck
      flycheck-pos-tip
      magit
      paredit
    ];
    pname = "my-prog";
    src = ./my-prog.el;
    version = "0.0.0";
  };
}
