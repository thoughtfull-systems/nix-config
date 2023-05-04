self: super: {
  my = self.elpaBuild {
    packageRequires = with self; [
      nix-mode
    ];
    pname = "my";
    src = ./my.el;
    version = "0.0.0";
  };
}
