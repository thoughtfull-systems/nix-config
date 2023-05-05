self: super: {
  my-completion = self.elpaBuild {
    packageRequires = with self; [
      orderless
      use-package
    ];
    pname = "my-completion";
    src = ./my-completion.el;
    version = "0.0.0";
  };
}
