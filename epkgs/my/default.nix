self: super: {
  my = self.elpaBuild {
    packageRequires = with self; [
      all-the-icons
      all-the-icons-completion
      all-the-icons-dired
      all-the-icons-ibuffer
      nix-mode
      use-package
    ];
    pname = "my";
    src = ./my.el;
    version = "0.0.0";
  };
}
