epkgs: {
  my-completion = epkgs.elpaBuild {
    packageRequires = with epkgs; [
      marginalia
      orderless
      use-package
    ];
    pname = "my-completion";
    src = ./my-completion.el;
    version = "0.0.0";
  };
}
