epkgs: {
  my-prog = epkgs.elpaBuild {
    packageRequires = with epkgs; [
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
